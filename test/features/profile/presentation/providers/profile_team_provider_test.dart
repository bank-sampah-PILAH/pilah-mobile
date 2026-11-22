import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

void main() {
  late StubApi api;
  late TestProfileNotifier notifier;
  late ProviderContainer container;
  late ProviderSubscription<ProfileState> subscription;

  setUp(() {
    api = StubApi();
    notifier = buildProfileNotifier(api);
    container = ProviderContainer(
      overrides: [profileProvider.overrideWith(() => notifier)],
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
  });

  group('createInvite after the role moved', () {
    test('a refusal reloads the roster so the screen follows', () async {
      stubProfile(api, team: {
        'members': [
          _member('u1', 'Siti', primary: true, me: true),
          _member('u2', 'Andi'),
        ],
      });
      await notifier.load();
      api.on('POST', '/api/v1/team/invite', status: 403, json: {
        'error': 'Hanya Pengurus Utama yang bisa membuat tautan undangan'
      });
      stubProfile(api, team: {
        'members': [
          _member('u1', 'Siti', me: true),
          _member('u2', 'Andi', primary: true),
        ],
      });

      final error = await notifier.createInvite();
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(error!.displayMessage,
          'Hanya Pengurus Utama yang bisa membuat tautan undangan');
      final state = container.read(profileProvider);
      expect(state.team.any((m) => m.isCurrentUser && m.isPrimary), isFalse);
      expect(state.invite, isNull);
    });

    test('another failure leaves the roster alone', () async {
      stubProfile(api);
      await notifier.load();
      final before = api.requests.length;
      api.on('POST', '/api/v1/team/invite',
          status: 400, json: {'error': 'Bank sampah belum aktif'});

      await notifier.createInvite();

      expect(api.requests.length, before + 1);
    });
  });
}
