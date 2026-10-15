import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/authentication/data/auth_repository_impl.dart';
import 'package:pilah_mobile/features/authentication/data/local/auth_local_data_sources.dart';
import 'package:pilah_mobile/features/authentication/data/remote/auth_remote_data_sources.dart';
import 'package:pilah_mobile/features/authentication/data/remote/model/request/save_token_request.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/authentication/data/remote/model/request/post_login_request.dart';
import 'package:pilah_mobile/features/authentication/data/remote/model/responses/auth_response.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';

import '../../../support/auth_data_support.dart';
import '../../../support/stub_api.dart';

class _MockLocal extends Mock implements AuthLocalDataSources {}

void main() {
  late StubApi api;
  late AuthStack stack;

  setUp(() {
    api = StubApi(accessToken: '');
    stack = AuthStack(api);
  });

  group('password login', () {
    test('maps the response into the session entity', () async {
      // `Endpoints.login` is `auth/login` without a leading slash, so the request
      // goes to `http://api.testauth/login` (host `api.testauth`). Recorded as a
      // suspected bug; the stub matches the path the client really sends.
      api.on('POST', '/login', json: authPayload(bankStatus: 'active'));

      final result = await stack.interactor.postLogin('siti', 'rahasia');

      final auth = result.getOrElse(() => throw StateError('failed'));
      expect(auth.name, 'Siti Aminah');
      expect(auth.token, 'access-1');
      expect(auth.role, 'pengelola');
      expect(auth.bankSampahStatus, 'active');
      expect(auth.noHp, '+62812');
      expect(auth.photoUrl, contains('Siti%20Aminah'));
      expect(api.last.json, {'username': 'siti', 'password': 'rahasia'});
    });

    test('a rejected login is a failure', () async {
      api.on('POST', '/login',
          status: 401, json: {'error': 'Kredensial salah'});

      final result = await stack.interactor.postLogin('siti', 'x');

      expect(
          result.fold((l) => l.displayMessage, (r) => ''), 'Kredensial salah');
    });

    test('the request serialises its fields', () {
      expect(const PostLoginRequest(username: 'a', password: 'b').toJson(),
          {'username': 'a', 'password': 'b'});
    });

    test('the response round-trips through JSON', () {
      final response = AuthResponse.fromJson(authPayload());

      final again = AuthResponse.fromJson(
          jsonDecode(jsonEncode(response)) as Map<String, dynamic>);

      expect(again.user.name, 'Siti Aminah');
      expect(again.accessToken, 'access-1');
      expect(response.user.toJson()['role'], 'pengelola');
    });
  });

  group('Google sign-in', () {
    test('a known account is persisted and returned as a session', () async {
      api.on('POST', '/api/v1/auth/google', json: authPayload());

      final result = await stack.repository.loginWithGoogle('id-token');

      final outcome = result.getOrElse(() => throw StateError('failed'));
      expect(outcome, isA<GoogleSession>());
      expect((outcome as GoogleSession).auth.token, 'access-1');
      expect(api.last.json, {'id_token': 'id-token'});
      expect(api.utils.accessToken, 'access-1');
      expect(await stack.database.getString('token'), 'access-1');
      expect(await stack.database.getString('refresh_token'), 'refresh-1');
    });

    test('a new account needs a role before it is created', () async {
      api.on('POST', '/api/v1/auth/google', json: {
        'registration_required': true,
        'registration_token': 'reg-1',
        'expires_in': 120,
        'google_profile': {
          'name': 'Siti',
          'email': 's@x.test',
          'picture': 'https://img.test/p.png',
        },
      });

      final result = await stack.repository.loginWithGoogle('id-token');

      final outcome = result.getOrElse(() => throw StateError('failed'))
          as GoogleRegistrationRequired;
      expect(outcome.registrationToken, 'reg-1');
      expect(outcome.expiresIn, 120);
      expect(outcome.name, 'Siti');
      expect(outcome.photoUrl, 'https://img.test/p.png');
      expect(api.utils.accessToken, isEmpty);
    });

    test('a bare registration request falls back to safe defaults', () async {
      api.on('POST', '/api/v1/auth/google',
          json: {'registration_required': true});

      final result = await stack.repository.loginWithGoogle('id-token');

      final outcome = result.getOrElse(() => throw StateError('failed'))
          as GoogleRegistrationRequired;
      expect(outcome.registrationToken, '');
      expect(outcome.expiresIn, 600);
      expect(outcome.email, '');
    });

    test('a server or network failure is a Left', () async {
      api.on('POST', '/api/v1/auth/google',
          status: 401, json: {'error': 'Token tidak valid'});

      final result = await stack.repository.loginWithGoogle('bad');

      expect(
          result.fold((l) => l.displayMessage, (r) => ''), 'Token tidak valid');
    });

    test('a malformed body is a general failure, not a crash', () async {
      api.on('POST', '/api/v1/auth/google', json: ['bukan', 'map']);

      final result = await stack.repository.loginWithGoogle('id-token');

      expect(result.fold((l) => l, (r) => null), isA<GeneralException>());
    });
  });

  group('registering a Google user', () {
    test('creates the account with the chosen role and saves the session',
        () async {
      api.on('POST', '/api/v1/auth/google/register', json: authPayload());

      final result = await stack.repository.registerGoogleUser(
          registrationToken: 'reg-1', role: GoogleRegistrationRole.pengelola);

      expect(result.isRight(), isTrue);
      expect(
          api.last.json, {'registration_token': 'reg-1', 'role': 'pengelola'});
      expect(api.utils.accessToken, 'access-1');
    });

    test('an expired registration is a failure', () async {
      api.on('POST', '/api/v1/auth/google/register',
          status: 400, json: {'error': 'Kedaluwarsa'});

      final result = await stack.repository.registerGoogleUser(
          registrationToken: 'old', role: GoogleRegistrationRole.nasabah);

      expect(result.fold((l) => l.displayMessage, (r) => ''), 'Kedaluwarsa');
    });

    test('a malformed body is a general failure', () async {
      api.on('POST', '/api/v1/auth/google/register', json: ['x']);

      final result = await stack.repository.registerGoogleUser(
          registrationToken: 'r', role: GoogleRegistrationRole.pengelolaInduk);

      expect(result.fold((l) => l, (r) => null), isA<GeneralException>());
    });
  });

  group('session', () {
    test('saving tokens keeps them in memory and storage', () async {
      final result = await stack.interactor.saveToken('a', 'r');

      expect(result.isRight(), isTrue);
      expect(api.utils.accessToken, 'a');
      expect(await stack.database.getString('refresh_token'), 'r');
    });

    test('a storage failure while saving tokens is reported, not thrown',
        () async {
      final local = _MockLocal();
      registerFallbackValue(
          const SaveTokenRequest(accessToken: '', refreshToken: ''));
      when(() => local.saveToken(any())).thenThrow(Exception('keystore'));
      final repository =
          AuthRepositoryImpl(AuthRemoteDataSourceImpl(api.network), local);

      final result = await repository.saveToken('a', 'r');

      expect(result.isLeft(), isTrue);
    });

    test('the current user is read from /auth/me', () async {
      api.on('GET', '/api/v1/auth/me', json: {
        'id': 'u1',
        'nama': 'Siti',
        'email': 's@x.test',
        'state': 'approval_pending',
        'role': 'pengelola',
        'no_hp': '+62812',
        'bank_sampah_nama': 'Bank A',
        'bank_sampah_status': 'pending',
      });

      final me = (await stack.interactor.getMe())
          .getOrElse(() => throw StateError('failed'));

      expect(me.name, 'Siti');
      expect(me.nextStep, 'approval_pending');
      expect(me.token, '');
    });

    test('a failed /auth/me is a failure', () async {
      api.on('GET', '/api/v1/auth/me', status: 401, json: {});

      expect((await stack.interactor.getMe()).isLeft(), isTrue);
    });

    test('hasSession reflects a stored access token', () async {
      expect(await stack.interactor.hasSession(), isFalse);

      stack = AuthStack(api, stored: {'token': 'abc'});
      expect(await stack.interactor.hasSession(), isTrue);

      stack = AuthStack(api, stored: {'token': ''});
      expect(await stack.interactor.hasSession(), isFalse);
    });

    test('logging out revokes the refresh token and clears the session',
        () async {
      stack = AuthStack(api, stored: {'token': 'a', 'refresh_token': 'r'});
      api.on('POST', '/api/v1/auth/logout', json: {});
      await api.utils.setToken(accessToken: 'a', refreshToken: 'r');

      final result = await stack.interactor.logout();

      expect(result.isRight(), isTrue);
      expect(api.last.json, {'refresh_token': 'r'});
      expect(api.utils.accessToken, isEmpty);
      expect(await stack.database.getString('token'), isNull);
    });

    test('logging out still clears locally when the server call fails',
        () async {
      stack = AuthStack(api, stored: {'token': 'a', 'refresh_token': 'r'});
      api.fail('POST', '/api/v1/auth/logout');

      final result = await stack.interactor.logout();

      expect(result.isRight(), isTrue);
      expect(await stack.database.getString('refresh_token'), isNull);
    });

    test('without a refresh token nothing is sent', () async {
      await stack.interactor.logout();

      expect(api.requests, isEmpty);
    });
  });
}
