import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/data/remote/model/mapper/auth_mapper.dart';
import 'package:pilah_mobile/features/authentication/data/remote/model/responses/auth_response.dart';
import '../../../support/auth_data_support.dart';

void main() {
  test('login retains owned roles while old single-role payloads still work',
      () {
    final payload = authPayload();
    payload['user'] = <String, dynamic>{
      ...payload['user'] as Map<String, dynamic>,
      'roles': ['pengelola', 'nasabah'],
    };
    final auth = AuthMapper.mapResponseToDomain(AuthResponse.fromJson(payload));
    expect(auth.ownedRoles, ['pengelola', 'nasabah']);
    final legacy =
        AuthMapper.mapResponseToDomain(AuthResponse.fromJson(authPayload()));
    expect(legacy.ownedRoles, ['pengelola']);
  });

  test('session restore preserves both owned roles and the active role', () {
    final auth = AuthMapper.mapMeResponseToDomain({
      'id': 'u1',
      'role': 'nasabah',
      'roles': ['pengelola', 'nasabah'],
    });
    expect(auth.role, 'nasabah');
    expect(auth.ownedRoles, ['pengelola', 'nasabah']);
  });
}
