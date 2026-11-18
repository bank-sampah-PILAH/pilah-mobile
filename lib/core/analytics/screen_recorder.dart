import 'package:flutter/widgets.dart';

/// An analytics client that records the screen and so needs something around
/// the app to see it. Kept apart from `AnalyticsClient` because that one is
/// also compiled for the browser test runner, which has no Flutter.
abstract interface class ScreenRecorder {
  /// Puts whatever recording needs around [app]. Keep [app] under a global key
  /// so that adding the recorder later does not rebuild it.
  Widget wrapApp(Widget app);
}
