import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_utils.dart';
import 'package:pilah_mobile/core/database/secure_database.dart';
import 'package:pilah_mobile/features/authentication/data/role_session_store.dart';

class Database extends Mock implements SecureDatabase {}

void main() {
  test('storage failure leaves both old tokens active', () async {
    final db = Database();
    when(() => db.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenThrow(StateError('keystore unavailable'));
    final network = NetworkUtils(db);
    await network.setToken(accessToken: 'old-access', refreshToken: 'old-refresh');
    await expectLater(RoleSessionStore(db, network).save('new-access', 'new-refresh'),
        throwsStateError);
    expect(network.accessToken, 'old-access');
    expect(network.refreshToken, 'old-refresh');
  });
}
