import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pilah_mobile/features/authentication/data/local/auth_local_data_sources.dart';
import 'package:pilah_mobile/features/authentication/data/remote/model/request/save_token_request.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_utils.dart';
import 'package:pilah_mobile/core/database/secure_database.dart';
import 'package:pilah_mobile/features/authentication/data/role_session_store.dart';

class Database extends Mock implements SecureDatabase {}

void main() {
  test('logout during a keystore write cannot resurrect switched tokens', () async {
    final db = Database();
    final entered = Completer<void>();
    final release = Completer<void>();
    final disk = <String, String>{};
    when(() => db.write(key: any(named: 'key'), value: any(named: 'value')))
      .thenAnswer((call) async {
        entered.complete();
        await release.future;
        disk[call.namedArguments[#key] as String] = call.namedArguments[#value] as String;
      });
    when(() => db.getString(any())).thenAnswer((call) async => disk[call.positionalArguments.single]);
    when(() => db.delete(any())).thenAnswer((call) async { disk.remove(call.positionalArguments.single); });
    final network = NetworkUtils(db);
    await network.setToken(accessToken: 'old', refreshToken: 'old-refresh');
    final saving = RoleSessionStore(db, network).save('new', 'new-refresh');
    await entered.future;
    await network.deleteToken();
    release.complete();
    await expectLater(saving, throwsStateError);
    expect(network.accessToken, isEmpty);
    expect(network.refreshToken, isEmpty);
    expect(disk[RoleSessionStore.key], isNull);
  });

  test('a subsequent login supersedes the switched session on restart', () async {
    FlutterSecureStorage.setMockInitialValues({});
    const db = SecureDatabaseImpl();
    final network = NetworkUtils(db);
    await RoleSessionStore(db, network).save('switched', 'switched-refresh');
    final local = AuthLocalDataSourcesImpl(db, network);
    await local.saveToken(const SaveTokenRequest(
      accessToken: 'login', refreshToken: 'login-refresh'));
    final restored = NetworkUtils(db);
    await restored.init();
    expect(restored.accessToken, 'login');
    expect(restored.refreshToken, 'login-refresh');
  });

  test('logout removes the switched session from disk and memory', () async {
    FlutterSecureStorage.setMockInitialValues({});
    const db = SecureDatabaseImpl();
    final network = NetworkUtils(db);
    await RoleSessionStore(db, network).save('new-access', 'new-refresh');
    final local = AuthLocalDataSourcesImpl(db, network);
    await local.clearToken();
    final restored = NetworkUtils(db);
    await restored.init();
    expect(restored.accessToken, isEmpty);
    expect(restored.refreshToken, isEmpty);
    expect(network.accessToken, isEmpty);
    expect(await local.readAccessToken(), isNull);
  });

  test('cold start restores the switched access and refresh tokens together', () async {
    FlutterSecureStorage.setMockInitialValues({
      'token': 'legacy-access', 'refresh_token': 'legacy-refresh',
    });
    const db = SecureDatabaseImpl();
    final network = NetworkUtils(db);
    await RoleSessionStore(db, network).save('new-access', 'new-refresh');
    final restored = NetworkUtils(db);
    await restored.init();
    expect(restored.accessToken, 'new-access');
    expect(restored.refreshToken, 'new-refresh');
    final local = AuthLocalDataSourcesImpl(db, restored);
    expect(await local.readAccessToken(), 'new-access');
    expect(await local.readRefreshToken(), 'new-refresh');
  });

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
