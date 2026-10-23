import 'dart:async';

import 'package:pilah_mobile/core/client/app_environment.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import '../../../../support/beranda_pengumuman_support.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/router/app_router_config.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/pengumuman/data/nasabah_pengumuman_repository.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_approval_provider.dart';
import 'package:pilah_mobile/services/di.dart';
import '../../../../support/approved_membership.dart';
import '../../../../support/auth_support.dart';

class _Environment extends Mock implements AppEnvironment {}

/// Counts calls to [profile] so a pull-to-refresh test can assert the load
/// ran again, without caring how many times the widget tree rebuilds.
class _CountingNasabahRepository extends PreviewNasabahRepository {
  _CountingNasabahRepository({required super.name, required super.email});
  int profileCalls = 0;

  @override
  Future<NasabahIdentity> profile() {
    profileCalls++;
    return super.profile();
  }
}

// Proposed first slice for PIL-226, not an external ticket specification.
// Editing personal details, membership APIs, and logout are separate slices.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final router = AppRouterConfig.getRouter();
  tearDownAll(router.dispose);
  Future<void> openProfile(
    WidgetTester tester, {
    String name = 'Siti Aminah',
    String email = 'siti@example.test',
    String route = '/profile',
    String? apiName,
    bool membershipActive = true,
    TestAuthenticationNotifier? authNotifier,
    NasabahRepository? repository,
  }) async {
    final auth = authNotifier ??
        authNotifierIn(Authenticated(
          authEntity: AuthEntity(
            id: 'nasabah-226',
            name: name,
            email: email,
            photoUrl: '',
            token: 'test-token',
            role: 'nasabah',
            nextStep: 'dashboard',
            bankSampahStatus: membershipActive ? 'active' : 'pending',
            bankSampahNama: 'Bank Sampah Melati',
          ),
        ));
    final approval = buildApprovedMembershipNotifier();
    final invites = InviteTokenStore();
    final environment = _Environment();
    when(() => environment.supportsDemoLogin).thenReturn(false);
    di.registerSingleton<AppEnvironment>(environment);
    di.registerSingleton<InviteTokenStore>(invites);
    di.registerSingleton<NasabahRepository>(repository ??
        PreviewNasabahRepository(name: apiName ?? name, email: email));
    registerNasabahPengumumanRepository();
    addTearDown(() => di.unregister<NasabahPengumumanRepository>());
    addTearDown(() async {
      await di.unregister<AppEnvironment>();
      await di.unregister<InviteTokenStore>();
      await di.unregister<NasabahRepository>();
      invites.dispose();
    });
    router.go(route);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        nasabahApprovalProvider.overrideWith(() => approval),
        authenticationProvider.overrideWith(() => auth),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  group('PIL-226 profil nasabah — proposed RED slice', () {
    testWidgets(
        'logout clears customer identity without loading staff settings',
        (tester) async {
      final auth = authNotifierIn(Authenticated(
        authEntity: AuthEntity(
          id: 'nasabah-226',
          name: 'Siti Aminah',
          email: 'siti@example.test',
          photoUrl: '',
          token: 'test-token',
          role: 'nasabah',
          nextStep: 'dashboard',
          bankSampahStatus: 'active',
          bankSampahNama: 'Bank Sampah Melati',
        ),
      ));
      await openProfile(tester, authNotifier: auth);
      expect(find.text('siti@example.test'), findsOneWidget);
      auth.setStateForTest(Unauthenticated());
      await tester.pumpAndSettle();
      expect(find.text('siti@example.test'), findsNothing);
      expect(router.routeInformationProvider.value.uri.path, '/login');
    });
    testWidgets('akses Profil dari Beranda membuka profil akun',
        (tester) async {
      await openProfile(tester, route: '/dashboard');
      final entry = find.byTooltip('Profil');
      expect(entry, findsOneWidget,
          reason:
              'Avatar perlu menjadi akses Profil yang berlabel dan dapat diketuk');
      await tester.tap(entry);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/profile');
      expect(find.text('siti@example.test'), findsOneWidget);
    });

    for (final user in [
      (name: 'Siti Aminah', email: 'siti@example.test'),
      (name: 'Budi Santoso', email: 'budi@example.test'),
    ]) {
      testWidgets('profil menampilkan identitas sesi ${user.name}',
          (tester) async {
        await openProfile(tester, name: user.name, email: user.email);
        expect(find.text(user.name), findsOneWidget);
        expect(find.text(user.email), findsOneWidget);
        expect(
            find.text(user.email == 'siti@example.test'
                ? 'budi@example.test'
                : 'siti@example.test'),
            findsNothing);
      });
    }

    testWidgets('profile refreshes server identity without active membership',
        (tester) async {
      await openProfile(tester,
          name: 'Old session name',
          apiName: 'Updated API name',
          membershipActive: false);
      expect(find.text('Updated API name'), findsOneWidget);
      expect(find.text('Old session name'), findsNothing);
    });

    testWidgets('role nasabah tidak dilabeli Pengelola', (tester) async {
      await openProfile(tester);
      expect(find.text('Nasabah'), findsOneWidget);
      expect(find.text('Pengelola'), findsNothing);
    });

    testWidgets('profil nasabah tidak menawarkan pengaturan bank dan tim',
        (tester) async {
      await openProfile(tester);
      expect(find.text('Pengaturan Umum'), findsNothing);
      expect(find.text('Manajemen Tim'), findsNothing);
      expect(find.text('PROFIL BANK SAMPAH'), findsNothing);
      expect(find.text('Simpan Pengaturan'), findsNothing);
    });

    testWidgets('profil nasabah tidak meminta data pengaturan pengelola',
        (tester) async {
      await openProfile(tester);
    });

    testWidgets('menarik layar ke bawah memuat ulang profil (PIL-285)',
        (tester) async {
      final repository = _CountingNasabahRepository(
        name: 'Siti Aminah',
        email: 'siti@example.test',
      );
      await openProfile(tester, repository: repository);
      expect(repository.profileCalls, 1);
      expect(find.byTooltip('Muat ulang'), findsNothing,
          reason: 'the manual refresh button is replaced by pull-to-refresh');

      unawaited(
        tester
            .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
            .show(),
      );
      await tester.pumpAndSettle();

      expect(repository.profileCalls, 2);
    });
  });
}
