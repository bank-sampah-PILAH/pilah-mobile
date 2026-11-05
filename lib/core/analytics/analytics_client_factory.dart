// Picks the analytics client for this platform: PostHog on the web when the
// build is configured for it, the no-op client everywhere else.
export 'analytics_client_factory_stub.dart'
    if (dart.library.js_interop) 'analytics_client_factory_web.dart';
