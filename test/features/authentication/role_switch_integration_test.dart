import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/onboarding/data/datasources/onboarding_remote_data_source.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:pilah_mobile/features/pengumuman/data/nasabah_pengumuman_repository.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/providers/nasabah_pengumuman_provider.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/providers/pengumuman_provider.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/states/nasabah_pengumuman_state.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/states/pengumuman_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/transaksi_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/riwayat_aktivitas_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/states/transaksi_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/states/riwayat_aktivitas_state.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/core/client/network_utils.dart';
import 'package:pilah_mobile/core/database/secure_database.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/role_switch_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/profile/domain/entities/profile_entities.dart';
import 'package:pilah_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:pilah_mobile/features/profile/presentation/states/profile_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/aktivitas_selection_provider.dart';
import 'package:pilah_mobile/services/di.dart';
import '../../support/auth_support.dart';
import '../../support/auth_data_support.dart';
import '../../support/profile_support.dart';
import '../../support/stub_api.dart';
import '../../support/pengumuman_support.dart';
import '../../support/transaksi_support.dart';

class _UnusedOnboardingSource implements OnboardingRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Only the local profile draft is used');
}

void main() {
  tearDown(() => di.reset());
  // Supplemental regression coverage added after the coordinator was GREEN;
  // these cases are not claimed as additional demonstrated RED cycles.
  test(
      'HTTP rejection, outage and malformed payload preserve session and caches',
      () async {
    for (final scenario in ['forbidden', 'server', 'offline', 'malformed']) {
      final api = StubApi(accessToken: 'old');
      final stack =
          AuthStack(api, stored: {'token': 'old', 'refresh_token': 'refresh'});
      if (scenario == 'offline') {
        api.fail('POST', '/api/v1/auth/switch-role');
      } else {
        api.on('POST', '/api/v1/auth/switch-role',
            status: scenario == 'forbidden'
                ? 403
                : scenario == 'server'
                    ? 500
                    : 200,
            json: scenario == 'malformed'
                ? {'access_token': 'incomplete'}
                : {'error': 'refused', 'code': 'role_not_owned'});
      }
      di.registerSingleton<NetworkService>(api.network);
      di.registerSingleton<NetworkUtils>(api.utils);
      di.registerSingleton<SecureDatabase>(stack.database);
      final auth = authNotifierIn(Authenticated(
          authEntity: const AuthEntity(
              id: 'u1',
              name: '',
              email: '',
              photoUrl: '',
              token: 'old',
              role: 'pengelola',
              roles: ['pengelola', 'nasabah'])));
      final profile = TestProfileNotifier.noDataSource();
      final container = ProviderContainer(overrides: [
        authenticationProvider.overrideWith(() => auth),
        profileProvider.overrideWith(() => profile),
      ]);
      container.read(profileProvider);
      profile.setStateForTest(const ProfileState(
          waTemplate: WaTemplate(template: 'current-role-template')));
      final before = container.read(authenticationProvider);
      final coordinator = container.read(roleSwitchProvider);
      await coordinator.switchTo('nasabah');
      expect(container.read(authenticationProvider), same(before),
          reason: scenario);
      expect(container.read(profileProvider).waTemplate!.template,
          'current-role-template');
      expect(api.utils.accessToken, 'old');
      expect(api.utils.refreshToken, 'refresh');
      expect(await stack.local.readAccessToken(), 'old');
      expect(await stack.local.readRefreshToken(), 'refresh');
      expect(coordinator.error, isNotNull);
      expect(coordinator.busy, isFalse);
      expect(api.requests, hasLength(1),
          reason: 'switch POST must not retry automatically');
      container.dispose();
      await di.reset();
    }
  });

  test('real switch clears role caches before publishing the new session',
      () async {
    final api = StubApi();
    final stack = AuthStack(api);
    final announcementPage = {
      'count': 1,
      'next': null,
      'results': [
        {
          'id': 'old-announcement',
          'bank_sampah_id': 'old-bank',
          'judul': 'Private old announcement',
          'isi': 'Old role information',
          'status': 'terbit',
        }
      ],
    };
    api.on('GET', '/api/v1/pengumuman', json: announcementPage);
    api.on('GET', '/api/v1/nasabah/me/pengumuman', json: announcementPage);
    final transaction = {
      'id': 'old-transaction',
      'nasabah_nama': 'Old role customer',
      'total_berat_kg': '1.5',
      'total_nilai': 1000,
    };
    api.on('GET', '/api/v1/transaksi', json: {
      'results': [transaction]
    });
    api.on('GET', '/api/v1/aktivitas', json: {
      'count': 1,
      'next': null,
      'results': [
        {'tipe': 'setoran', 'data': transaction}
      ],
      'summary': {
        'jumlah_transaksi': 1,
        'total_berat': '1.5',
        'total_setoran': 1000,
        'total_pencairan': 0,
        'saldo': 1000
      },
    });
    api.on('POST', '/api/v1/auth/switch-role',
        json: authPayload(role: 'nasabah', nextStep: 'nasabah_dashboard'));
    di.registerSingleton<NetworkService>(api.network);
    di.registerSingleton<NetworkUtils>(api.utils);
    di.registerSingleton<SecureDatabase>(stack.database);
    final auth = authNotifierIn(Authenticated(
        authEntity: const AuthEntity(
            id: 'u1',
            name: 'Siti',
            email: '',
            photoUrl: '',
            token: 'token-123',
            role: 'pengelola',
            roles: ['pengelola', 'nasabah'])));
    final profile = TestProfileNotifier.noDataSource();
    final container = ProviderContainer(overrides: [
      authenticationProvider.overrideWith(() => auth),
      profileProvider.overrideWith(() => profile),
      pengumumanProvider.overrideWith(
          () => PengumumanNotifier(buildPengumumanRepository(api))),
      nasabahPengumumanProvider.overrideWith(() =>
          NasabahPengumumanNotifier(NasabahPengumumanRepository(api.network))),
      transaksiProvider.overrideWith(() => buildTransaksiNotifier(api)),
      riwayatAktivitasProvider
          .overrideWith(() => buildRiwayatAktivitasNotifier(api)),
      onboardingProvider
          .overrideWith(() => OnboardingNotifier(_UnusedOnboardingSource())),
    ]);
    addTearDown(container.dispose);
    final announcements = container.listen(pengumumanProvider, (_, __) {});
    final customerAnnouncements =
        container.listen(nasabahPengumumanProvider, (_, __) {});
    addTearDown(announcements.close);
    addTearDown(customerAnnouncements.close);
    await Future.wait([
      container.read(pengumumanProvider.notifier).loadPengumuman(),
      container.read(nasabahPengumumanProvider.notifier).load(),
      container.read(transaksiProvider.notifier).loadTransaksi(),
      container.read(riwayatAktivitasProvider.notifier).load(),
    ]);
    container.read(onboardingProvider.notifier).saveProfileDraft(
        const CompleteProfileRequest(
            nama: 'Old profile draft',
            jenisKelamin: 'perempuan',
            tanggalLahir: '1990-04-17',
            noHp: '81234567890'));
    expect(
        (container.read(pengumumanProvider) as PengumumanLoaded)
            .items
            .single
            .judul,
        'Private old announcement');
    expect(container.read(nasabahPengumumanProvider).items.single.id,
        'old-announcement');
    expect(
        (container.read(transaksiProvider) as TransaksiLoaded)
            .transaksiList
            .single
            .transactions
            .single
            .id,
        'old-transaction');
    expect(container.read(riwayatAktivitasProvider).items.single.title,
        'Old role customer');
    expect(container.read(onboardingProvider.notifier).hasProfileDraft, isTrue);
    container.read(profileProvider);
    profile.setStateForTest(const ProfileState(
        status: ProfileStatus.loaded,
        waTemplate: WaTemplate(template: 'private old template')));
    container
        .read(aktivitasSelectionProvider.notifier)
        .select('old-transaction');
    var published = false;
    container.listen(authenticationProvider, (_, next) {
      if (next is Authenticated && next.authEntity.role == 'nasabah') {
        published = true;
        expect(container.read(profileProvider).waTemplate, isNull);
        expect(container.read(aktivitasSelectionProvider), isNull);
        expect(container.read(pengumumanProvider), isA<PengumumanInitial>());
        expect(container.read(nasabahPengumumanProvider),
            const NasabahPengumumanState());
        expect(container.read(transaksiProvider), isA<TransaksiInitial>());
        expect(container.read(riwayatAktivitasProvider),
            const RiwayatAktivitasState());
        expect(container.read(onboardingProvider.notifier).hasProfileDraft,
            isFalse);
        expect(api.utils.accessToken, 'access-1');
        expect(api.utils.refreshToken, 'refresh-1');
      }
    });
    await container.read(roleSwitchProvider).switchTo('nasabah');
    expect(published, isTrue);
    expect(
        (container.read(authenticationProvider) as Authenticated)
            .authEntity
            .role,
        'nasabah');
  });
}
