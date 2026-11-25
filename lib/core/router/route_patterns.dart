import 'package:go_router/go_router.dart';

/// The route patterns of [routes], such as `/nasabah/:id`, with the path of
/// every parent in front. A shell has no path of its own, so its pages are
/// listed as they are.
List<String> routePatternsOf(List<RouteBase> routes, [String parent = '']) => [
      for (final route in routes) ..._patternsOf(route, parent),
    ];

List<String> _patternsOf(RouteBase route, String parent) {
  if (route is! GoRoute) return routePatternsOf(route.routes, parent);
  final path = route.path.startsWith('/')
      ? route.path
      : '${parent.endsWith('/') ? parent : '$parent/'}${route.path}';
  return [path, ...routePatternsOf(route.routes, path)];
}
