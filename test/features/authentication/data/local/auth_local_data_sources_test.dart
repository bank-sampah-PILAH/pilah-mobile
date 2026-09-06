import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_utils.dart';
import 'package:pilah_mobile/core/constants/app_key.dart';
import 'package:pilah_mobile/core/database/secure_database.dart';
import 'package:pilah_mobile/features/authentication/data/local/auth_local_data_sources.dart';
import 'package:pilah_mobile/features/authentication/data/remote/model/request/save_token_request.dart';

class _MockSecureDatabase extends Mock implements SecureDatabase {}

void main() {
  late _MockSecureDatabase db;
  late NetworkUtils networkUtils;
  late AuthLocalDataSourcesImpl dataSource;

  const request = SaveTokenRequest(
    accessToken: 'access-123',
    refreshToken: 'refresh-456',
  );

  setUp(() {
    db = _MockSecureDatabase();
    // NetworkUtils reads storage only in init(); construct it with the mock and
    // exercise the in-memory setters directly.
    networkUtils = NetworkUtils(db);
    dataSource = AuthLocalDataSourcesImpl(db, networkUtils);
  });

  group('saveToken', () {
    test('sets the in-memory token so the session is authenticated immediately',
        () async {
      when(() => db.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      await dataSource.saveToken(request);

      expect(networkUtils.accessToken, 'access-123');
      expect(networkUtils.refreshToken, 'refresh-456');
    });

    test('keeps the session in memory even when secure storage write throws',
        () async {
      // A real device-specific failure: the keystore rejects the write.
      when(() => db.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenThrow(Exception('keystore unavailable'));

      // Must not rethrow — a storage failure cannot become a login failure.
      await dataSource.saveToken(request);

      expect(
        networkUtils.accessToken,
        'access-123',
        reason: 'the in-memory token authenticates the current session and '
            'must survive a secure-storage failure',
      );
    });

    test('writes the token to secure storage under the expected keys',
        () async {
      when(() => db.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      await dataSource.saveToken(request);

      verify(() => db.write(key: AppKey.token, value: 'access-123')).called(1);
      verify(() => db.write(key: AppKey.refreshToken, value: 'refresh-456'))
          .called(1);
    });
  });

  group('clearToken', () {
    test('clears the in-memory session even when secure storage delete throws',
        () async {
      when(() => db.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});
      await dataSource.saveToken(request);
      expect(networkUtils.accessToken, isNotEmpty);

      when(() => db.delete(any())).thenThrow(Exception('keystore unavailable'));

      await dataSource.clearToken();

      expect(
        networkUtils.accessToken,
        isEmpty,
        reason:
            'logout must deauthenticate the session even if the delete fails',
      );
    });
  });
}
