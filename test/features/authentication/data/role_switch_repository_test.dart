import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/data/role_switch_repository.dart';
import '../../../support/stub_api.dart';
import '../../../support/auth_data_support.dart';

void main() {
  test('requests a session-scoped switch with the current bearer token',
      () async {
    final api = StubApi(accessToken: 'old-access');
    api.on('POST', '/api/v1/auth/switch-role',
        json: authPayload(role: 'nasabah', nextStep: 'nasabah_dashboard'));
    final next = await RoleSwitchRepository(api.network).request('nasabah');
    expect(api.requests, hasLength(1));
    expect(api.last.json, {'role': 'nasabah'});
    expect(api.last.headers['Authorization'], 'Bearer old-access');
    expect(next.auth.role, 'nasabah');
    expect(next.auth.nextStep, 'nasabah_dashboard');
    expect(next.auth.token, 'access-1');
    expect(next.refreshToken, 'refresh-1');
    expect(api.utils.accessToken, 'old-access',
        reason: 'request must not persist');
  });
}
