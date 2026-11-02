import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:web/web.dart' as web;

/// Loads PostHog's browser library only when [start] is called, so nothing
/// reaches PostHog before the user has agreed to be recorded.
class PosthogWebClient implements AnalyticsClient {
  /// [libraryUrl] defaults to the library served next to [host]; tests pass
  /// their own so they never reach the network.
  PosthogWebClient({
    required this.apiKey,
    required this.host,
    String? libraryUrl,
  }) : libraryUrl = libraryUrl ?? _libraryUrlFor(host);

  final String apiKey;
  final String host;
  final String libraryUrl;

  /// `https://us.i.posthog.com` is served by `https://us-assets.i.posthog.com`.
  static String _libraryUrlFor(String host) =>
      '${host.replaceFirst('.i.', '-assets.i.')}/static/array.js';

  Future<void>? _starting;

  @override
  Future<void> start() => _starting ??= _load();

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
    await loaded.future;

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
