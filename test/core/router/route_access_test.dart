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
}
