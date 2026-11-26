import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:pilah_mobile/core/router/auth_routing.dart';

/// Which roles may open a path, and where a refused request is sent.
///
/// The router used to answer this from two hand-written path sets and treat
/// every path outside both as unprotected, so each route added afterwards was
/// open to every role until someone remembered to list it. Here the table is
/// the whole answer and it fails closed: a path with no entry is refused, so a
/// new route stays shut until it is given one.
///
/// A path inherits the entry of its longest matching ancestor, matched by whole
/// segments. `/transaksi-baru/panel` and `/jadwal/:id` therefore need no entry
/// of their own, while `/nasabah-dashboard` is not treated as a child of
/// `/nasabah` the way a plain string prefix would have it.
const _access = <String, Set<String>>{
  '/transaksi-baru': {'pengelola'},
  superadminDashboardLocation: {'superadmin'},
};

/// Where a refused [role] is sent. Its own home, so the bounce lands somewhere
/// it is allowed to be rather than on another refusal.
String _homeFor(String? role) => switch (role) {
      'nasabah' || 'pengelola' => AppLocations.dashboard,
      'superadmin' => superadminDashboardLocation,
      _ => '/login',
    };

/// The entry governing [path]: its own, or its closest declared ancestor's.
Set<String>? _entryFor(String path) {
  final segments = path.split('/').where((s) => s.isNotEmpty).toList();
  for (var depth = segments.length; depth > 0; depth--) {
    final candidate = '/${segments.take(depth).join('/')}';
    final allowed = _access[candidate];
    if (allowed != null) return allowed;
  }
  return null;
}

/// `null` when [role] may open [path], otherwise where to send it instead.
String? roleRouteRedirect({required String path, required String? role}) {
  final allowed = _entryFor(path);
  if (allowed != null && role != null && allowed.contains(role)) return null;
  return _homeFor(role);
}
