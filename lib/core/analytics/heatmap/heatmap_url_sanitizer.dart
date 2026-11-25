/// Turns the address a click happened on into the route pattern of its screen,
/// so a heatmap can say where people click without an id, or anything else in
/// the address, leaving the app.
class HeatmapUrlSanitizer {
  /// [patterns] are the app's route patterns, such as `/nasabah/:id`.
  HeatmapUrlSanitizer(this.patterns);

  final List<String> patterns;

  /// The address without its values: `https://app/#/nasabah/:id`.
  String? sanitize(String url) {
    final uri = Uri.parse(url);
    final path = uri.fragment.split('?').first;
    final segments = _segments(path);
    String? best;
    var bestFixed = -1;
    for (final pattern in patterns) {
      final parts = _segments(pattern);
      if (!_matches(parts, segments)) continue;
      // `/nasabah/new` is a screen of its own, not a nasabah called "new".
      final fixed = parts.where((s) => !s.startsWith(':')).length;
      if (fixed > bestFixed) {
        best = pattern;
        bestFixed = fixed;
      }
    }
    return best == null ? null : '${uri.origin}/#$best';
  }

  static List<String> _segments(String path) =>
      path.split('/').where((s) => s.isNotEmpty).toList();

  static bool _matches(List<String> pattern, List<String> segments) {
    if (pattern.length != segments.length) return false;
    for (var i = 0; i < pattern.length; i++) {
      if (!pattern[i].startsWith(':') && pattern[i] != segments[i])
        return false;
    }
    return true;
  }
}
