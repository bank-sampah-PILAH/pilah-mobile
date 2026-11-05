import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:pilah_mobile/core/analytics/analytics_props.dart';
import 'package:web/web.dart' as web;

/// Loads PostHog's browser library only when [start] is called, so nothing
/// reaches PostHog before the user has agreed to analytics.
///
/// The library is a script PostHog serves and can change, loaded from
/// [libraryUrl]; a web deployment with a Content-Security-Policy has to allow
/// that address.
class PosthogWebClient implements AnalyticsClient {
  /// [libraryUrl] defaults to the library served next to [host]; tests pass
  /// their own so they never reach the network. A library that has not arrived
  /// after [loadTimeout] counts as failed.
  PosthogWebClient({
    required this.apiKey,
    required this.host,
    this.environment,
    this.recordScreen = false,
    String? libraryUrl,
    this.loadTimeout = const Duration(seconds: 15),
  }) : libraryUrl = libraryUrl ?? _libraryUrlFor(host);

  final String apiKey;
  final String host;

  /// `staging` or `production`: both share one PostHog project, so every event
  /// says which one it came from.
  final String? environment;

  /// Whether the library also records the screen. Flutter draws everything on
  /// one canvas, so the recording is a picture of it: it is only safe together
  /// with the masks `PosthogWebRecordingClient` supplies, and until those are
  /// in place every frame is skipped.
  final bool recordScreen;
  final String libraryUrl;
  final Duration loadTimeout;

  /// `https://us.i.posthog.com` is served by `https://us-assets.i.posthog.com`.
  static String _libraryUrlFor(String host) =>
      '${host.replaceFirst('.i.', '-assets.i.')}/static/array.js';

  Future<void>? _starting;
  bool _stopped = false;

  /// Loaded and not stopped: the only time events may leave the app.
  bool _live = false;

  /// Counts every stop, so a start that is still waiting for the library knows
  /// whether a stop came after it. A second start does not count: it asks for
  /// the same thing, and must not leave the first one's caller dropped.
  int _stops = 0;

  /// The library is loaded and set up, so its methods can be called.
  bool _ready = false;

  @override
  bool get isAvailable => true;

  @override
  bool get recordsScreen => recordScreen;

  /// Starts the client. Throws a [StateError] when the library cannot be
  /// loaded, so a caller has to handle that. A failed start is not remembered:
  /// the next call tries again.
  @override
  Future<void> start() async {
    final stopsBefore = _stops;
    final starting = _starting ??= _load();
    starting.then<void>((_) {}, onError: (Object _) {
      if (identical(_starting, starting)) _starting = null;
    });
    await starting;
    if (_stopped) {
      // Started again after a stop: the library is already loaded and set up,
      // so it only has to be switched back on.
      _stopped = false;
      final posthog = globalContext.getProperty<JSObject>('posthog'.toJS);
      posthog.callMethod('opt_in_capturing'.toJS, _optInOptions.jsify());
      _registerContext(posthog);
    }
    // A stop that came while the library was loading is the later decision.
    if (stopsBefore == _stops) _live = true;
  }

  @override
  Future<void> stop() async {
    _stops++;
    _live = false;
    final starting = _starting;
    // Never started, so there is nothing to stop and nothing to load.
    if (starting == null) return;
    try {
      await starting;
    } catch (_) {
      // The library never loaded, so nothing is running that could be stopped.
      // Failing here would stop a pengurus's withdrawal from being saved.
      return;
    }

    final posthog = globalContext.getProperty<JSObject>('posthog'.toJS);
    posthog.callMethod('opt_out_capturing'.toJS);
    _stopped = true;
  }

  @override
  void capture(String event, [Map<String, Object?> properties = const {}]) {
    if (!_live) return;
    _posthog.callMethod(
      'capture'.toJS,
      event.toJS,
      AnalyticsProps.sanitize(properties).jsify(),
    );
  }

  @override
  void identify(String id) {
    final clean = AnalyticsProps.cleanId(id);
    if (!_live || clean == null) return;
    _posthog.callMethod('identify'.toJS, clean.toJS);
  }

  @override
  void register(Map<String, Object?> properties) {
    if (!_live) return;
    _posthog.callMethod(
      'register'.toJS,
      AnalyticsProps.sanitize(properties).jsify(),
    );
  }

  @override
  void reset() {
    // Never loaded: nothing was identified, so there is nothing to forget.
    if (!_ready) return;
    _posthog.callMethod('reset'.toJS);
  }

  @override
  void screen(String name, [Map<String, Object?> properties = const {}]) {
    if (!_live) return;
    _posthog.callMethod(
      'capture'.toJS,
      r'$screen'.toJS,
      {r'$screen_name': name, ...AnalyticsProps.sanitize(properties)}.jsify(),
    );
  }

  JSObject get _posthog => globalContext.getProperty<JSObject>('posthog'.toJS);

  Future<void> _load() async {
    final loaded = Completer<void>();
    final script = web.HTMLScriptElement()
      ..async = true
      ..src = libraryUrl;
    script.addEventListener('load', ((web.Event _) => loaded.complete()).toJS);
    script.addEventListener(
      'error',
      ((web.Event _) => loaded.completeError(
            StateError('Could not load the PostHog library from $libraryUrl'),
          )).toJS,
    );
    web.document.head!.append(script);
    try {
      await loaded.future.timeout(
        loadTimeout,
        onTimeout: () => throw StateError(
          'Timed out loading the PostHog library from $libraryUrl',
        ),
      );
    } catch (_) {
      script.remove();
      rethrow;
    }

    if (!globalContext.has('posthog')) {
      throw StateError(
        'The library loaded from $libraryUrl did not define posthog',
      );
    }
    final posthog = globalContext.getProperty<JSObject>('posthog'.toJS);
    final options = _options().jsify() as JSObject;
    if (recordScreen) _addRecording(options);
    posthog.callMethod('init'.toJS, apiKey.toJS, options);
    _ready = true;
    // PostHog keeps an opt-out across page reloads, so one made on an earlier
    // visit would still be in force. start() is only called once the pengurus
    // has agreed, so switch capturing on.
    posthog.callMethod('opt_in_capturing'.toJS, _optInOptions.jsify());
    _registerContext(posthog);
  }

  /// Where this runs, told to the library and carried by every event after. The
  /// library forgets it when it is reset on sign-out, so every start tells it
  /// again; telling it twice does no harm.
  void _registerContext(JSObject posthog) {
    posthog.callMethod(
      'register'.toJS,
      AnalyticsProps.sanitize({
        'platform': 'web',
        'environment': environment,
        'kelas_layar': _screenClass(),
      }).jsify(),
    );
  }

  /// A rough size of the screen, to tell a phone from a desktop in the results.
  /// It is measured once, when the library starts: resizing the window later
  /// keeps the first value, which is accurate enough for a bucket.
  static String _screenClass() => screenClassFor(web.window.innerWidth);

  /// The class of a window [width] pixels wide. Public so a test can reach the
  /// boundaries without resizing a browser window.
  static String screenClassFor(num width) {
    final wider = (width >= 600 ? 1 : 0) + (width >= 1024 ? 1 : 0);
    return const ['ponsel', 'tablet', 'desktop'][wider];
  }

  /// Opting in sends an event of PostHog's own by default, which would reach
  /// PostHog without passing the sanitizer.
  static const _optInOptions = {'captureEventName': false};

  /// What the recording may see. The canvas is sent as pictures with the
  /// rectangles to cover; until the app has said which, the function below
  /// answers null, which skips the frame instead of sending it uncovered.
  /// Whatever the page itself shows (the field the keyboard types into, the
  /// text of the page) is masked wholesale, and the copy of the widgets Flutter
  /// keeps for screen readers is not recorded. No network request is kept: the
  /// address of a call can carry an id.
  void _addRecording(JSObject options) {
    final recording = options.getProperty<JSObject>('session_recording'.toJS);
    final canvasCapture = recording.getProperty<JSObject>('canvasCapture'.toJS);
    canvasCapture.setProperty(
      'maskRegionsFn'.toJS,
      ((JSAny? _) => null).toJS,
    );
    recording.setProperty(
      'maskCapturedNetworkRequestFn'.toJS,
      ((JSAny? _) => null).toJS,
    );
  }

  Map<String, Object> _options() => {
        'api_host': host,
        // Only usage events are sent: no screen recording, no automatic
        // capture of clicks or page views, no heatmaps. Load time is the one
        // automatic measurement kept, to see how slow the app is to open.
        'disable_session_recording': !recordScreen,
        // The recording never carries the browser console: a debug build prints
        // what the server answered there, and that holds names.
        if (recordScreen) 'enable_recording_console_log': false,
        'autocapture': false,
        'capture_pageview': false,
        'enable_heatmaps': false,
        // posthog-js adds the address and referrer to every event by itself.
        // A route can carry an id, which the sanitizer never sees, so none of
        // them may leave the app.
        'property_denylist': [
          r'$current_url',
          r'$pathname',
          r'$referrer',
          r'$referring_domain',
          r'$host',
          // The same, recorded once for the first visit.
          r'$initial_current_url',
          r'$initial_pathname',
          r'$initial_referrer',
          r'$initial_referring_domain',
          r'$initial_host',
        ],
        // The denylist does not reach `$set_once`, where posthog-js sends the
        // `$initial_*` person properties it builds from storage. It only builds
        // them while it saves the referrer or the campaign parameters, so
        // neither is saved and the first visit's address is never stored.
        'save_referrer': false,
        'save_campaign_params': false,
        'capture_performance': true,
        if (recordScreen)
          'session_recording': {
            'maskAllInputs': true,
            'maskTextSelector': '*',
            'blockSelector': 'flt-semantics-host',
            'captureCanvas': {
              'recordCanvas': true,
              'canvasFps': 2,
              'canvasQuality': '0.4',
            },
            'canvasCapture': <String, Object>{},
          },
      };
}
