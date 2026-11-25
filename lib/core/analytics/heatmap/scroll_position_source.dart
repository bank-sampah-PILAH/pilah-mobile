/// Where the app's page is scrolled to. Kept apart from the widgets that find it
/// out, because the browser side of the heatmap is compiled for the browser test
/// runner, which has no Flutter.
abstract interface class ScrollPositionSource {
  /// How far the list under the last tap was scrolled, 0 for fixed chrome.
  double get tapOffset;

  /// How far the main list is scrolled right now.
  double get liveOffset;
}
