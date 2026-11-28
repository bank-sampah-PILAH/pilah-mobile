import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:pilah_mobile/core/router/auth_routing.dart';
import 'package:pilah_mobile/core/router/route_access.dart';

void main() {
  test('a nasabah is refused the staff setoran panel', () {
    expect(
      roleRouteRedirect(path: '/transaksi-baru/panel', role: 'nasabah'),
      AppLocations.dashboard,
    );
  });

  test('only a superadmin may open the superadmin dashboard', () {
    expect(
      roleRouteRedirect(path: superadminDashboardLocation, role: 'superadmin'),
      isNull,
    );
    for (final role in const ['pengelola', 'nasabah']) {
      expect(
        roleRouteRedirect(path: superadminDashboardLocation, role: role),
        AppLocations.dashboard,
        reason: role,
      );
    }
  });

  test('a path with no role gate is never refused', () {
    for (final path in const [
      '/login',
      '/splash',
      '/choose-role',
      '/forgot_password',
      '/invite',
      '/invite/web-token-9',
      '/legal',
      '/legal/privacy',
    ]) {
      for (final role in const [
        'nasabah',
        'pengelola',
        'superadmin',
        'tamu',
      ]) {
        expect(roleRouteRedirect(path: path, role: role), isNull,
            reason: '$role $path');
      }
    }
  });

  /// Paths each role may open. The staff and customer halves are the matrix
  /// `app_routes_test.dart` already drives through the real router; the rest
  /// are the paths that used to sit outside the guard's two sets entirely.
  const allowed = <String, List<String>>{
    'pengelola': [
      '/dashboard',
      '/profile',
      '/nasabah',
      '/harga',
      '/riwayat-harga',
      '/laporan',
      '/transaksi-baru',
      '/transaksi-baru/panel',
      '/edit-pencairan',
      '/riwayat-perubahan-pencairan',
      '/draft-pencairan',
      '/draft-pencairan/editor',
      '/pengumuman/kelola',
      '/pengumuman/kelola/ubah',
      '/jadwal',
      '/jadwal/42',
      '/complete-profile',
      '/register-bank-sampah',
      '/register-nasabah',
      '/pending-approval',
      '/invite-processing',
    ],
    'nasabah': [
      '/dashboard',
      '/profile',
      '/jadwal',
      '/jadwal/42',
      '/riwayat',
      '/bank-sampah',
      '/approval-bank-sampah',
      '/approval-bank-sampah/detail',
      '/pengumuman',
      '/pengumuman/detail',
      '/ajukan-bank-sampah',
      '/register-nasabah',
      '/complete-profile',
      '/nasabah-dashboard',
    ],
  };

  test('each role may open the paths that belong to its context', () {
    allowed.forEach((role, paths) {
      for (final path in paths) {
        expect(roleRouteRedirect(path: path, role: role), isNull,
            reason: '$role $path');
      }
    });
  });

  test('neither role may open the other context', () {
    const refused = <String, List<String>>{
      'pengelola': [
        '/riwayat',
        '/bank-sampah',
        '/approval-bank-sampah',
        '/pengumuman',
      ],
      'nasabah': [
        '/nasabah',
        '/harga',
        '/riwayat-harga',
        '/laporan',
        '/transaksi-baru',
        '/transaksi-baru/panel',
        '/edit-pencairan',
        '/riwayat-perubahan-pencairan',
        '/draft-pencairan',
        '/pengumuman/kelola',
      ],
    };

    refused.forEach((role, paths) {
      for (final path in paths) {
        expect(
            roleRouteRedirect(path: path, role: role), AppLocations.dashboard,
            reason: '$role $path');
      }
    });
  });

  test('a path nobody declared is refused rather than left open', () {
    // The point of the table: a route added later is shut until it is listed,
    // instead of being reachable by every role because nobody remembered it.
    for (final role in const ['pengelola', 'nasabah']) {
      expect(roleRouteRedirect(path: '/laporan-keuangan-baru', role: role),
          AppLocations.dashboard,
          reason: role);
    }
  });

  test('an unrecognised role is sent to the login page', () {
    expect(roleRouteRedirect(path: '/dashboard', role: 'tamu'), '/login');
    expect(roleRouteRedirect(path: '/dashboard', role: null), '/login');
  });

  test('a sibling path is not mistaken for a child of a shorter one', () {
    // `/nasabah-dashboard` shares a string prefix with the staff `/nasabah`
    // but not a path segment, so a nasabah keeps its alias and does not
    // inherit the staff entry.
    expect(
        roleRouteRedirect(path: '/nasabah-dashboard', role: 'nasabah'), isNull);
    expect(roleRouteRedirect(path: '/nasabah', role: 'nasabah'),
        AppLocations.dashboard);
  });
}
