import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:pilah_mobile/core/analytics/analytics_client.dart';
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
    String? libraryUrl,
    this.loadTimeout = const Duration(seconds: 15),
  }) : libraryUrl = libraryUrl ?? _libraryUrlFor(host);

  final String apiKey;
  final String host;
  final String libraryUrl;
  final Duration loadTimeout;

  /// `https://us.i.posthog.com` is served by `https://us-assets.i.posthog.com`.
  static String _libraryUrlFor(String host) =>
      '${host.replaceFirst('.i.', '-assets.i.')}/static/array.js';

  Future<void>? _starting;

  /// Starts the client. Throws a [StateError] when the library cannot be
  /// loaded, so a caller has to handle that. A failed start is not remembered:
  /// the next call tries again.
  @override
  Future<void> start() {
    final starting = _starting ??= _load();
    starting.then<void>((_) {}, onError: (Object _) {
      if (identical(_starting, starting)) _starting = null;
    });
    return starting;
  }

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
    posthog.callMethod('init'.toJS, apiKey.toJS, _options().jsify());
  }

  Map<String, Object> _options() => {
        'api_host': host,
        // Only usage events are sent: no screen recording, no automatic
        // capture of clicks or page views, no heatmaps.
        'disable_session_recording': true,
        'autocapture': false,
        'capture_pageview': false,
        'enable_heatmaps': false,
      };
}
