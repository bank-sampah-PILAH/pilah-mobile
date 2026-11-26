import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:pilah_mobile/core/router/route_access.dart';

void main() {
  test('a nasabah is refused the staff setoran panel', () {
    expect(
      roleRouteRedirect(path: '/transaksi-baru/panel', role: 'nasabah'),
      AppLocations.dashboard,
    );
  });
}
