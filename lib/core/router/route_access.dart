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
/// Listed with no roles: open to any session. Whether there is a session at
/// all is settled before the role is ever consulted, by [sessionRestoreRedirect]
/// and [signedOutRedirect].
const _anyRole = <String>{};

/// Both app roles. Superadmin keeps its own dashboard and is refused these.
const _onboarding = <String>{'nasabah', 'pengelola'};

const _access = <String, Set<String>>{
  '/splash': _anyRole,
  '/login': _anyRole,
  '/choose-role': _anyRole,
  '/forgot_password': _anyRole,
  '/invite': _anyRole,
  '/legal': _anyRole,
  // Onboarding and invite redemption stay open to both app roles. The step the
  // server reports decides which one a session is sent to, and the second-role
  // flows (PIL-541, PIL-542) walk a Nasabah through bank registration and an
  // invite, so gating these by role would shut the door on them.
  '/complete-profile': _onboarding,
  '/register-nasabah': _onboarding,
  '/ajukan-bank-sampah': _onboarding,
  '/register-bank-sampah': _onboarding,
  '/pending-approval': _onboarding,
  '/invite-processing': _onboarding,
  '/nasabah-dashboard': _onboarding,
  // Shared shell.
  AppLocations.dashboard: _onboarding,
  AppLocations.profile: _onboarding,
  '/jadwal': _onboarding,
  // Staff.
  '/nasabah': {'pengelola'},
  '/harga': {'pengelola'},
  '/riwayat-harga': {'pengelola'},
  '/laporan': {'pengelola'},
  '/transaksi-baru': {'pengelola'},
  '/edit-pencairan': {'pengelola'},
  '/riwayat-perubahan-pencairan': {'pengelola'},
  '/draft-pencairan': {'pengelola'},
  '/pengumuman/kelola': {'pengelola'},
  // Customer. `/pengumuman` is the nasabah's own list; its `kelola` subtree
  // above is the staff side and outranks it, being the longer match.
  AppLocations.history: {'nasabah'},
  AppLocations.customerBank: {'nasabah'},
  '/approval-bank-sampah': {'nasabah'},
  '/pengumuman': {'nasabah'},
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
  if (allowed == null) return _homeFor(role);
  if (allowed.isEmpty) return null;
  return role != null && allowed.contains(role) ? null : _homeFor(role);
}
