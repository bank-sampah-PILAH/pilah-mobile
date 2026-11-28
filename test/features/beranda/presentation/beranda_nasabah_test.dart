import 'dart:async';
import 'dart:ui' show SemanticsAction;

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/app_environment.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/core/router/app_router_config.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';

import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/active_membership_selection.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/active_membership_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/widgets/bank_membership_panel.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_approval_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/states/nasabah_approval_state.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_bank_detail.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_page_result.dart';
import 'package:pilah_mobile/features/jadwal/domain/repositories/jadwal_repository.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/riwayat_pencairan_filter.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:pilah_mobile/services/di.dart';
import '../../../support/active_membership_support.dart';
import '../../../support/approved_membership.dart';
import '../../../support/nasabah_approval_support.dart';
import '../../../support/auth_support.dart';
import '../../../support/fake_riwayat.dart';
import '../../../support/profile_support.dart';

/// Counts calls to [home] so a pull-to-refresh test can assert the load ran
/// again, without caring how many times the widget tree rebuilds.
class _CountingNasabahRepository extends PreviewNasabahRepository {
  _CountingNasabahRepository({required super.bankName});
  int homeCalls = 0;
  String balanceAmount = '12500.50';

  @override
  Future<NasabahHome> home({String? membershipId}) {
    homeCalls++;
    return super.home(membershipId: membershipId);
  }

  @override
  Future<NasabahBalance> balance(String membershipId) async =>
      NasabahBalance(balanceAmount, null);
}

class _JadwalRepository extends Mock implements JadwalRepository {}

class _PayoutUseCases extends Mock implements PencairanUseCases {}

class _TestAppEnvironment implements AppEnvironment {
  const _TestAppEnvironment();

  @override
  String get baseUrl => 'https://example.test';

  @override
  bool get supportsDemoLogin => false;

  @override
  String get demoPengurusEmail => '';

  @override
  String get demoCustomerEmail => '';

  @override
  String get demoNewNasabahEmail => '';

  @override
  String get demoSuperadminEmail => '';
}

// First TDD slice: the landing screen and its entry points. Destination pages
// and their data will be covered in subsequent slices, without inventing URLs.
// The current session contract has no separate membership-status field:
// dashboard + nasabah + active bank is the available onboarded-session fixture.
AuthEntity _nasabah(String bankName) => AuthEntity(
      id: 'nasabah-225',
      name: 'Siti Aminah',
      email: 'siti@example.test',
      photoUrl: '',
      token: 'test-token',
      role: 'nasabah',
      nextStep: 'nasabah_dashboard',
      bankSampahStatus: 'active',
      bankSampahNama: bankName,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final router = AppRouterConfig.getRouter();
  tearDownAll(router.dispose);
  setUpAll(() => registerFallbackValue(const RiwayatPencairanFilter()));
  // Setoran rows for the Tabungan screen's RiwayatHistoryCubit (one page).
  final riwayatFixture = FakeRiwayatRemoteDataSource(pages: [
    [
      NasabahActivity('t1', DateTime(2026, 9, 23), 'setoran', '12500.00'),
    ],
  ]);

  Future<void> loginAsNasabah(
    WidgetTester tester, {
    String bankName = 'Bank Sampah Melati',
    NasabahRepository? repository,
    bool activeBank = false,
  }) async {
    final auth = authNotifierIn(Unauthenticated());
    final jadwalRepository = _JadwalRepository();
    final invites = InviteTokenStore();
    final payoutUseCases = _PayoutUseCases();
    when(() => payoutUseCases.getRiwayat(any())).thenAnswer(
      (_) async => const Right<NetworkException, List<Pencairan>>([]),
    );

    when(() => jadwalRepository.getJadwal(
        page: 1, date: null, membershipId: 'preview-membership')).thenAnswer(
      (_) async => Right(const JadwalPageResult(
        items: [],
        totalCount: 0,
        hasMore: false,
      )),
    );

    final storage = MemoryAppStorage();
    if (activeBank) {
      await ActiveMembershipSelection(storage)
          .select('nasabah-225', 'membership');
    }
    final approval = activeBank
        ? TestNasabahApprovalNotifier(
            initialState: const NasabahApprovalLoaded([
              NasabahMembershipEntity(
                id: 'membership',
                bankSampahId: 'bank',
                bankSampahNama: 'Bank Sampah Melati',
                bankSampahKota: 'Bandung',
                bankSampahAlamat: 'Jl. Melati',
                status: MembershipStatus.approved,
                isActive: true,
                dapatDibuka: true,
              ),
            ]),
          )
        : buildApprovedMembershipNotifier();
    di.registerSingleton<AppEnvironment>(const _TestAppEnvironment());
    di.registerSingleton<InviteTokenStore>(invites);
    di.registerSingleton<NasabahRepository>(
        repository ?? PreviewNasabahRepository(bankName: bankName));
    di.registerSingleton<JadwalRepository>(jadwalRepository);
    di.registerFactory<PencairanUseCases>(() => payoutUseCases);
    registerFakeRiwayat(riwayatFixture);
    addTearDown(() async {
      await di.unregister<AppEnvironment>();
      await di.unregister<InviteTokenStore>();
      await di.unregister<PencairanUseCases>();
      await unregisterFakeRiwayat();
      await di.unregister<NasabahRepository>();
      await di.unregister<JadwalRepository>();
      invites.dispose();
    });

    router.go(LoginPage.route);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nasabahApprovalProvider.overrideWith(() => approval),
          if (activeBank)
            activeMembershipSelectionProvider.overrideWithValue(
              ActiveMembershipSelection(storage),
            ),
          // The shell watches the profile for its logo; no data source here.
          profileProvider.overrideWith(SilentProfileNotifier.new),
        ],
        child: withAuthenticationProvider(
          auth,
          MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);

    // Exercise the production login listener and router, not a test-only route.
    auth.setStateForTest(Authenticated(authEntity: _nasabah(bankName)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(LoginPage), findsNothing);
  }

  group('PIL-225 beranda nasabah — first red slice', () {
    testWidgets('nasabah aktif mendarat di Beranda setelah login', (
      tester,
    ) async {
      await loginAsNasabah(tester);
      expect(find.text('Beranda'), findsWidgets);
    });

    testWidgets('saldo card is tappable and opens Tabungan', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await loginAsNasabah(tester);
        final amount = find.text('Rp 12.500,50');
        await tester.scrollUntilVisible(amount, 200);
        await tester.pumpAndSettle();
        expect(find.text('Riwayat Aktivitas'), findsNothing);
        expect(find.text('Pencairan'), findsNothing);
        expect(
          tester
              .getSemantics(amount)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue,
        );
        await tester.tap(amount);
        await tester.pumpAndSettle();
        expect(find.text('Tabungan Saya'), findsOneWidget);
        expect(find.text('Riwayat Setoran'), findsOneWidget);
        expect(
          tester
              .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
              .currentIndex,
          1,
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('Bank sampah saya opens the full page on Bank Diikuti',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await loginAsNasabah(tester, activeBank: true);
        expect(
          find.descendant(
            of: find.byType(BankMembershipHomeCard),
            matching: find.text('Bank Sampah Melati'),
          ),
          findsOneWidget,
        );
        await tester.tap(find.text('Bank sampah saya'));
        await tester.pumpAndSettle();
        expect(find.text('Bank Diikuti'), findsOneWidget);
        expect(find.text('Riwayat pengajuan'), findsOneWidget);
        expect(find.text('Bank Sampah Melati'), findsWidgets);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('nasabah tidak melihat menu pengelola', (tester) async {
      await loginAsNasabah(tester);
      expect(find.text('Nasabah'), findsNothing);
      expect(find.text('Laporan'), findsNothing);
      expect(find.text('TOTAL KAS BULAN INI'), findsNothing);
    });

    testWidgets('active bank detail uses the mobile sheet and animated row',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await loginAsNasabah(tester, activeBank: true);
      await tester.tap(find.text('Bank sampah saya'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bank Sampah Melati').last);
      await tester.pumpAndSettle();
      expect(find.byType(NasabahBankDetail), findsOneWidget);
      expect(
          find.descendant(
              of: find.byType(NasabahBankDetail),
              matching: find.text('Jl. Melati')),
          findsOneWidget);
      expect(
          tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).turns,
          .5);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
          tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).turns,
          0);
      expect(tester.takeException(), isNull);
    });

    for (final bankName in ['Bank Sampah Melati', 'Bank Sampah Kenanga']) {
      testWidgets('menampilkan unit milik akun: $bankName', (tester) async {
        await loginAsNasabah(tester, bankName: bankName);
        expect(
          find.textContaining('SALDO DI ${bankName.toUpperCase()}'),
          findsOneWidget,
        );
        final otherBank = bankName == 'Bank Sampah Melati'
            ? 'Bank Sampah Kenanga'
            : 'Bank Sampah Melati';
        expect(
          find.textContaining('SALDO DI ${otherBank.toUpperCase()}'),
          findsNothing,
        );
      });
    }

    testWidgets('menarik layar ke bawah memuat ulang beranda (PIL-285)',
        (tester) async {
      final repository =
          _CountingNasabahRepository(bankName: 'Bank Sampah Melati');
      await loginAsNasabah(tester, repository: repository);
      expect(repository.homeCalls, 1);
      expect(find.byTooltip('Muat ulang'), findsNothing,
          reason: 'the manual refresh button is replaced by pull-to-refresh');

      unawaited(
        tester
            .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
            .show(),
      );
      await tester.pumpAndSettle();

      expect(repository.homeCalls, 2);
    });

    testWidgets('resuming refreshes the latest saldo from the server', (
      tester,
    ) async {
      final repository =
          _CountingNasabahRepository(bankName: 'Bank Sampah Melati');
      await loginAsNasabah(tester, repository: repository);
      expect(repository.homeCalls, 1);
      expect(find.text('Rp 12.500,50'), findsOneWidget);

      repository.balanceAmount = '25000.00';
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(repository.homeCalls, 2);
      expect(find.text('Rp 12.500,50'), findsNothing);
      expect(find.text('Rp 25.000'), findsOneWidget);
    });
  });
}
