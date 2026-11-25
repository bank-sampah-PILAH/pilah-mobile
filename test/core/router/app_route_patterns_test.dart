import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/router/app_router_config.dart';

void main() {
  test('the app lists its route patterns, ids and all', () {
    final patterns = AppRouterConfig.routePatterns();

    expect(patterns, containsAll(['/dashboard', '/invite/:token']));
    expect(patterns.where((p) => p.contains(':')), isNotEmpty);
  });
}
