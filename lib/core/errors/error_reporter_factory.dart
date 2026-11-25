// Picks the last link of the reporter chain for this platform: PostHog's
// browser library on the web, a no-op reporter everywhere else.
export 'error_reporter_factory_stub.dart'
    if (dart.library.js_interop) 'error_reporter_factory_web.dart';
