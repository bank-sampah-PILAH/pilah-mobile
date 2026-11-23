import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/domain/use_cases/authentication_use_cases.dart';
import 'package:pilah_mobile/features/authentication/domain/use_cases/login_with_google_usecase.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:pilah_mobile/features/profile/presentation/states/profile_state.dart';

import '../../../../support/profile_support.dart';
import '../../../../support/stub_api.dart';

Map<String, dynamic> _member(
  String id,
  String nama, {
  bool primary = false,
  bool me = false,
}) =>
    {
      'id': id,
      'nama': nama,
      'email': '$nama@x.test',
      'is_primary_pengelola': primary,
      'is_current_user': me,
    };

class _MockUseCases extends Mock implements AuthenticationUseCases {}

class _MockGoogle extends Mock implements LoginWithGoogleUseCase {}

AuthEntity _session({required bool primary}) => AuthEntity(
      id: 'u1',
      name: 'Siti',
      email: 'siti@x.test',
      photoUrl: '',
      token: 't',
      role: 'pengelola',
      isPrimaryPengelola: primary,
    );

void main() {
  late _MockUseCases useCases;
  late StubApi api;
  late TestProfileNotifier notifier;
  late ProviderContainer container;
  late ProviderSubscription<ProfileState> subscription;

  setUp(() {
    api = StubApi();
    notifier = buildProfileNotifier(api);
    useCases = _MockUseCases();
    when(() => useCases.getMe())
        .thenAnswer((_) async => Right(_session(primary: true)));
    container = ProviderContainer(
      overrides: [
        profileProvider.overrideWith(() => notifier),
        authenticationProvider.overrideWith(
            () => AuthenticationNotifier(useCases, _MockGoogle())),
      ],
    );
    subscription = container.listen(profileProvider, (_, __) {});
  });

  tearDown(() {
    subscription.close();
    container.dispose();
  });

  group('transferPrimary', () {
    setUp(() {
      stubProfile(api, team: {
        'members': [
          _member('u1', 'Siti', primary: true, me: true),
          _member('u2', 'Andi'),
        ],
      });
      api.on('GET', '/api/v1/team/invite', json: {
        'token': 't',
        'invite_url': 'https://pilah.test/invite/t',
        'expires_at': '2030-01-04T12:00:00Z',
      });
    });

    test('posts the chosen pengurus and takes the roster from the answer',
        () async {
      await notifier.load();
      api.on('POST', '/api/v1/team/transfer', json: {
        'members': [
          _member('u2', 'Andi', primary: true),
          _member('u1', 'Siti', me: true),
        ],
      });

      final error = await notifier.transferPrimary('u2');

      expect(error, isNull);
      expect(api.last.method, 'POST');
      expect(api.last.path, '/api/v1/team/transfer');
      expect(api.last.json, {'id': 'u2'});
      final state = container.read(profileProvider);
      expect(state.team.map((m) => m.nama), ['Andi', 'Siti']);
      expect(state.team.first.isPrimary, isTrue);
      expect(state.team.any((m) => m.isCurrentUser && m.isPrimary), isFalse);
      expect(state.isChangingTeam, isFalse);
    });

    test('drops the invitation link the former owner no longer controls',
        () async {
      await notifier.load();
      expect(container.read(profileProvider).invite, isNotNull);
      api.on('POST', '/api/v1/team/transfer', json: {
        'members': [
          _member('u2', 'Andi', primary: true),
          _member('u1', 'Siti', me: true),
        ],
      });

      await notifier.transferPrimary('u2');

      final state = container.read(profileProvider);
      expect(state.invite, isNull);
      expect(state.inviteError, isNull);
    });

    test('keeps the roster and reports the refusal', () async {
      await notifier.load();
      api.on('POST', '/api/v1/team/transfer', status: 403, json: {
        'error': 'Hanya pengelola utama yang dapat melakukan aksi ini'
      });

      final error = await notifier.transferPrimary('u2');

      expect(error!.displayMessage,
          'Hanya pengelola utama yang dapat melakukan aksi ini');
      final state = container.read(profileProvider);
      expect(state.team.map((m) => m.nama), ['Siti', 'Andi']);
      expect(state.team.first.isPrimary, isTrue);
      expect(state.isChangingTeam, isFalse);
    });

    group('the session', () {
      final handedOver = {
        'members': [
          _member('u2', 'Andi', primary: true),
          _member('u1', 'Siti', me: true),
        ],
      };

      bool? marker() {
        final state = container.read(authenticationProvider);
        return state is Authenticated
            ? state.authEntity.isPrimaryPengelola
            : null;
      }

      test('is read again after a hand-over and loses the marker', () async {
        await container.read(authenticationProvider.notifier).refreshUser();
        expect(marker(), isTrue);
        await notifier.load();
        when(() => useCases.getMe())
            .thenAnswer((_) async => Right(_session(primary: false)));
        api.on('POST', '/api/v1/team/transfer', json: handedOver);

        await notifier.transferPrimary('u2');

        expect(marker(), isFalse);
        verify(() => useCases.getMe()).called(2);
      });

      test('is left alone when the hand-over is refused', () async {
        await container.read(authenticationProvider.notifier).refreshUser();
        await notifier.load();
        api.on('POST', '/api/v1/team/transfer', status: 403, json: {
          'error': 'Hanya pengelola utama yang dapat melakukan aksi ini'
        });

        await notifier.transferPrimary('u2');
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(marker(), isTrue);
        verify(() => useCases.getMe()).called(1);
      });
    });

    group('while a hand-over is in flight', () {
      final handedOver = {
        'members': [
          _member('u2', 'Andi', primary: true),
          _member('u1', 'Siti', me: true),
        ],
      };

      test('a second tap does not start a second hand-over', () async {
        await notifier.load();
        api.on('POST', '/api/v1/team/transfer', json: handedOver);
        api.delay(
            'POST', '/api/v1/team/transfer', const Duration(milliseconds: 60));

        final first = notifier.transferPrimary('u2');
        final second = await notifier.transferPrimary('u2');
        await first;

        expect(second, isNull);
        expect(api.requests.where((r) => r.method == 'POST'), hasLength(1));
      });

      test('a refresh keeps the screen locked until the answer is in',
          () async {
        await notifier.load();
        api.on('POST', '/api/v1/team/transfer', json: handedOver);
        api.delay(
            'POST', '/api/v1/team/transfer', const Duration(milliseconds: 80));

        final transfer = notifier.transferPrimary('u2');
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(container.read(profileProvider).isChangingTeam, isTrue);
        await notifier.load(silent: true);

        expect(container.read(profileProvider).isChangingTeam, isTrue);
        await transfer;
        expect(container.read(profileProvider).isChangingTeam, isFalse);
      });

      test('a roster fetched before the hand-over cannot overwrite it',
          () async {
        await notifier.load();
        // The pre-transfer snapshot takes its time; the hand-over overtakes it.
        api.delay('GET', '/api/v1/team', const Duration(milliseconds: 120));
        api.on('POST', '/api/v1/team/transfer', json: handedOver);

        final stale = notifier.load(silent: true);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await notifier.transferPrimary('u2');
        await stale;

        final state = container.read(profileProvider);
        expect(state.team.map((m) => m.nama), ['Andi', 'Siti']);
        expect(state.team.first.isPrimary, isTrue);
        expect(state.invite, isNull);
      });

      test('a refresh after the hand-over is applied as usual', () async {
        await notifier.load();
        api.on('POST', '/api/v1/team/transfer', json: handedOver);
        await notifier.transferPrimary('u2');
        stubProfile(api, team: {
          'members': [
            _member('u2', 'Andi', primary: true),
            _member('u1', 'Siti', me: true),
            _member('u3', 'Budi'),
          ],
        });

        await notifier.load(silent: true);

        expect(container.read(profileProvider).team.map((m) => m.nama),
            ['Andi', 'Siti', 'Budi']);
      });
    });

    test('a failure to reach the server keeps the roster and unlocks',
        () async {
      await notifier.load();
      api.fail('POST', '/api/v1/team/transfer');

      final error = await notifier.transferPrimary('u2');

      expect(error, isNotNull);
      final state = container.read(profileProvider);
      expect(state.isChangingTeam, isFalse);
      expect(state.team.map((m) => m.nama), ['Siti', 'Andi']);
    });

    test('a refusal reloads the roster so the screen converges', () async {
      await notifier.load();
      api.on('POST', '/api/v1/team/transfer', status: 403, json: {
        'error': 'Hanya pengelola utama yang dapat melakukan aksi ini'
      });
      // The role moved elsewhere in the meantime.
      stubProfile(api, team: {
        'members': [
          _member('u1', 'Siti', me: true),
          _member('u2', 'Andi', primary: true),
        ],
      });
      final before = api.requests.where((r) => r.path == '/api/v1/team').length;

      final error = await notifier.transferPrimary('u2');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(error, isNotNull);
      expect(api.requests.where((r) => r.path == '/api/v1/team').length,
          before + 1);
      final state = container.read(profileProvider);
      expect(state.team.first.isPrimary, isFalse);
      expect(state.team.last.isPrimary, isTrue);
      expect(state.status, ProfileStatus.loaded);
      expect(state.isChangingTeam, isFalse);
    });
  });

  group('removeMember', () {
    setUp(() async {
      stubProfile(api, team: {
        'members': [
          _member('u1', 'Siti', primary: true, me: true),
          _member('u2', 'Andi'),
          _member('u3', 'Budi'),
        ],
      });
      await notifier.load();
    });

    test('deletes the pengurus and drops them from the roster', () async {
      api.on('DELETE', '/api/v1/team/u2', status: 204, json: null);

      final error = await notifier.removeMember('u2');

      expect(error, isNull);
      expect(api.last.method, 'DELETE');
      expect(api.last.path, '/api/v1/team/u2');
      final state = container.read(profileProvider);
      expect(state.team.map((m) => m.nama), ['Siti', 'Budi']);
      expect(state.isChangingTeam, isFalse);
    });

    test('keeps the roster and reports the refusal', () async {
      api.on('DELETE', '/api/v1/team/u2',
          status: 403,
          json: {'error': 'Anda tidak bisa mengeluarkan diri sendiri'});

      final error = await notifier.removeMember('u2');

      expect(
          error!.displayMessage, 'Anda tidak bisa mengeluarkan diri sendiri');
      final state = container.read(profileProvider);
      expect(state.team.map((m) => m.nama), ['Siti', 'Andi', 'Budi']);
      expect(state.isChangingTeam, isFalse);
    });

    test('drops the invitation link the server rotated with the removal',
        () async {
      api.on('GET', '/api/v1/team/invite', json: {
        'token': 't',
        'invite_url': 'https://pilah.test/invite/t',
        'expires_at': '2030-01-04T12:00:00Z',
      });
      await notifier.load();
      expect(container.read(profileProvider).invite, isNotNull);
      api.on('DELETE', '/api/v1/team/u2', status: 204, json: null);

      await notifier.removeMember('u2');

      final state = container.read(profileProvider);
      expect(state.invite, isNull);
      expect(state.inviteError, isNull);
    });

    test('a member who is already gone counts as removed', () async {
      api.on('DELETE', '/api/v1/team/u2',
          status: 404, json: {'error': 'Pengurus tidak ditemukan'});

      final error = await notifier.removeMember('u2');

      expect(error, isNull);
      final state = container.read(profileProvider);
      expect(state.team.map((m) => m.nama), ['Siti', 'Budi']);
      expect(state.isChangingTeam, isFalse);
    });

    test('a failure to reach the server keeps the roster and unlocks',
        () async {
      api.fail('DELETE', '/api/v1/team/u2');

      final error = await notifier.removeMember('u2');

      expect(error, isNotNull);
      final state = container.read(profileProvider);
      expect(state.team.map((m) => m.nama), ['Siti', 'Andi', 'Budi']);
      expect(state.isChangingTeam, isFalse);
    });
  });
}
