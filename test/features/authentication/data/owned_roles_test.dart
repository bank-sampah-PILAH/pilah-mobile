import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/data/remote/model/mapper/auth_mapper.dart';

void main() {
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
