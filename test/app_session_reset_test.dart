import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/app.dart';
import 'package:pilah_mobile/core/router/app_router_config.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/core/router/root_navigator_key.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/forgot_password_page.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_state.dart';
import 'package:pilah_mobile/features/harga/presentation/providers/harga_provider.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_state.dart';
import 'package:pilah_mobile/features/jadwal/presentation/providers/jadwal_provider.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_state.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';
import 'package:pilah_mobile/features/onboarding/data/datasources/onboarding_remote_data_source.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:pilah_mobile/features/pengumuman/data/nasabah_pengumuman_repository.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/cubit/nasabah_pengumuman_state.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/cubit/pengumuman_state.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/providers/nasabah_pengumuman_provider.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/providers/pengumuman_provider.dart';
import 'package:pilah_mobile/features/profile/presentation/cubit/profile_state.dart';
import 'package:pilah_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/riwayat_aktivitas_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/transaksi_provider.dart';
import 'package:pilah_mobile/services/di.dart';

import 'support/auth_support.dart';
import 'support/harga_support.dart';
import 'support/jadwal_provider_support.dart';
import 'support/nasabah_support.dart';
import 'support/pengumuman_support.dart';
import 'support/profile_support.dart';
import 'support/stub_api.dart';
import 'support/transaksi_support.dart';

class _MockOnboardingDataSource extends Mock
    implements OnboardingRemoteDataSource {}

void main() {
  late InviteTokenStore invites;

  setUp(() {
    invites = InviteTokenStore();
    if (di.isRegistered<InviteTokenStore>()) {
      di.unregister<InviteTokenStore>();
    }
    di.registerSingleton<InviteTokenStore>(invites);
  });

  tearDown(() async => di.reset());

  testWidgets(
      'resetSessionScopedState keeps a pending invite token across logout',
      (tester) async {
    invites.save('invite-token-abc');
    final api = StubApi();
    api.on('GET', '/api/v1/nasabah/me/pengumuman',
        json: {'count': 0, 'next': null, 'results': []});
    api.on('GET', '/api/v1/pengumuman',
        json: {'count': 0, 'next': null, 'results': []});
    final repository = buildPengumumanRepository(api);
    final profile = buildProfileNotifier(StubApi());
    final container = ProviderContainer(overrides: [
      nasabahProvider.overrideWith(() => buildNasabahNotifier(api)),
      hargaProvider.overrideWith(() => buildHargaNotifier(api)),
      transaksiProvider.overrideWith(() => buildTransaksiNotifier(api)),
      riwayatAktivitasProvider.overrideWith(
        () => buildRiwayatAktivitasNotifier(api),
      ),
      jadwalProvider.overrideWith(
        () => TestJadwalNotifier(
          repository: UnusedJadwalRepository(),
          initialState: const JadwalLoaded([]),
        ),
      ),
      nasabahPengumumanProvider.overrideWith(
        () => NasabahPengumumanNotifier(
          NasabahPengumumanRepository(api.network),
        ),
      ),
      pengumumanProvider.overrideWith(
        () => PengumumanNotifier(repository),
      ),
      onboardingProvider.overrideWith(
        () => OnboardingNotifier(_MockOnboardingDataSource()),
      ),
      profileProvider.overrideWith(() => profile),
    ]);

    container.read(nasabahProvider);
    container.read(hargaProvider);
    container.read(transaksiProvider);
    container.read(riwayatAktivitasProvider);
    container.read(jadwalProvider);
    container.read(onboardingProvider.notifier).saveProfileDraft(
          const CompleteProfileRequest(
            nama: 'Sari Dewi',
            jenisKelamin: 'perempuan',
            tanggalLahir: '1990-04-17',
            noHp: '81234567890',
          ),
        );
    final nasabahPengumumanSub = container.listen(
      nasabahPengumumanProvider,
      (_, __) {},
    );
    final pengumumanSub = container.listen(pengumumanProvider, (_, __) {});
    final profileSub = container.listen(profileProvider, (_, __) {});
    profile.setStateForTest(ProfileState(
      selectedLogoBytes: Uint8List.fromList([1]),
      selectedLogoFilename: 'previous.png',
    ));
    await tester.runAsync(() async {
      await container.read(nasabahPengumumanProvider.notifier).load();
      await container.read(pengumumanProvider.notifier).loadPengumuman();
    });
    expect(container.read(pengumumanProvider), isA<PengumumanLoaded>());

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => resetSessionScopedState(context),
            child: const Text('logout'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('logout'));
    await tester.pump();

    expect(invites.hasToken, isTrue);
    expect(container.read(nasabahProvider), isA<NasabahInitial>());
    expect(container.read(hargaProvider), isA<HargaInitial>());
    expect(container.read(jadwalProvider), isA<JadwalInitial>());
    expect(container.read(transaksiProvider), isA<TransaksiInitial>());
    expect(container.read(riwayatAktivitasProvider),
        const RiwayatAktivitasState());
    expect(container.read(profileProvider), const ProfileState());
    expect(container.read(nasabahPengumumanProvider).status,
        NasabahPengumumanStatus.initial);
    expect(container.read(pengumumanProvider), isA<PengumumanInitial>());
    expect(
        container.read(onboardingProvider.notifier).hasProfileDraft, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    nasabahPengumumanSub.close();
    pengumumanSub.close();
    profileSub.close();
    container.dispose();
  });

  testWidgets('logs out and warns when a web session has an unsupported role',
      (tester) async {
    final auth = TestAuthenticationNotifier();
    await tester.pumpWidget(App(
      isWebOverride: true,
      providerScopeBuilder: (child) => ProviderScope(
        overrides: [authenticationProvider.overrideWith(() => auth)],
        child: child,
      ),
    ));
    final router = AppRouterConfig.getRouter();
    addTearDown(router.dispose);

    router.go(ForgotPasswordPage.route);
    await tester.pumpAndSettle();
    expect(rootNavigatorKey.currentContext, isNotNull);
    expect(find.text('Lupa kata sandi?'), findsOneWidget);

    auth.setStateForTest(Unauthenticated());
    await tester.pump();
    auth.setStateForTest(Authenticated(
      authEntity: const AuthEntity(
        name: 'Nasabah',
        email: 'nasabah@example.com',
        photoUrl: '',
        token: 'token',
        role: 'nasabah',
      ),
    ));
    for (var i = 0;
        i < 10 && find.text('Akses web tidak tersedia').evaluate().isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(auth.calls.where((call) => call == 'logout'), hasLength(1));
    expect(find.text('Akses web tidak tersedia'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
