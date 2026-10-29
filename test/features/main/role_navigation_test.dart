import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_approval_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/states/nasabah_approval_state.dart';
import 'package:pilah_mobile/features/main/presentation/pages/main_page.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_transaction_menu.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/transaksi_baru_page.dart';
import '../../support/auth_support.dart';
import '../../support/setoran_form_support.dart';
import '../../support/nasabah_approval_support.dart';

const pending = NasabahMembershipEntity(
  id: 'application-1',
  bankSampahId: 'bank-1',
  bankSampahNama: 'Bank Sampah Melati',
  bankSampahKota: 'Bandung',
  bankSampahAlamat: 'Jl. Melati',
  status: MembershipStatus.pending,
  isActive: true,
);

const approved = NasabahMembershipEntity(
  id: 'application-1',
  bankSampahId: 'bank-1',
  bankSampahNama: 'Bank Sampah Melati',
  bankSampahKota: 'Bandung',
  bankSampahAlamat: 'Jl. Melati',
  status: MembershipStatus.approved,
  isActive: true,
);

Authenticated session(String role) => Authenticated(
      authEntity: AuthEntity(
        name: 'Siti',
        email: 'siti@example.test',
        photoUrl: '',
        token: 'test',
        role: role,
        nextStep: 'dashboard',
      ),
    );

Future<GoRouter> mount(WidgetTester tester, AuthenticationStates state,
    {TestAuthenticationNotifier? authNotifier,
    NasabahApprovalState approvalState =
        const NasabahApprovalLoaded([approved]),
    TestNasabahApprovalNotifier? approvalNotifier,
    String initialLocation = '/home',
    bool settle = true,
    bool? isWebOverride}) async {
  final approval = approvalNotifier ??
      TestNasabahApprovalNotifier(initialState: approvalState);
  final auth = authNotifier ?? authNotifierIn(state);
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => MainPage(
          navigationShell: shell,
          isWebOverride: isWebOverride,
        ),
        branches: [
          for (final path in [
            '/home',
            '/customers',
            '/prices',
            '/reports',
            '/schedule',
            '/history',
            '/bank',
            '/profile'
          ])
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: path,
                  builder: (_, __) => Center(child: Text('body:$path')),
                ),
              ],
            ),
        ],
      ),
      GoRoute(
        path: TransaksiBaruPage.route,
        builder: (_, __) => const Scaffold(body: Text('Form Setoran')),
      ),
      GoRoute(
        path: '/approval-bank-sampah/detail',
        builder: (_, __) => const Text('application details'),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const Center(child: Text('login page')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      nasabahApprovalProvider.overrideWith(() => approval),
      authenticationProvider.overrideWith(() => auth),
    ],
    child: withSetoranFormProviders(
      child: MaterialApp.router(routerConfig: router),
    ),
  ));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump();
  }
  return router;
}

List<String?> labels(WidgetTester tester) => tester
    .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
    .items
    .map((item) => item.label)
    .toList();

void main() {
  testWidgets('changing roles resets an incompatible selected branch',
      (tester) async {
    final auth = authNotifierIn(session('nasabah'));
    final router = await mount(tester, session('nasabah'), authNotifier: auth);
    await tester.tap(find.text('Tabungan'));
    await tester.pumpAndSettle();
    auth.setStateForTest(session('pengelola'));
    await tester.pumpAndSettle();
    expect(labels(tester), [
      'Dashboard',
      'Nasabah',
      'Harga',
      'Aktivitas',
      'Jadwal',
    ]);
    expect(router.routeInformationProvider.value.uri.path, '/home');
    expect(find.text('body:/history'), findsNothing);
  });
  testWidgets(
    'nasabah receives customer destinations rather than staff menus',
    (tester) async {
      await mount(tester, session('nasabah'));
      expect(labels(tester), ['Beranda', 'Tabungan', 'Jadwal', 'Profil']);
      expect(find.text('Nasabah'), findsNothing);
      expect(find.text('Aktivitas'), findsNothing);
    },
  );

  for (final role in ['pengelola', 'pengelola_induk']) {
    testWidgets('$role retains the staff navigation', (tester) async {
      await mount(tester, session(role), isWebOverride: false);
      expect(find.text('Transaksi'), findsNothing,
          reason: 'the menu change applies to the web shell only');
      expect(labels(tester), [
        'Dashboard',
        'Nasabah',
        'Harga',
        'Aktivitas',
        'Jadwal',
      ]);
    });
  }

  testWidgets('Pengurus opens Setoran from the first web sidebar menu',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await mount(
      tester,
      session('pengelola'),
      isWebOverride: true,
    );

    expect(find.text('Transaksi'), findsOneWidget);
    expect(find.text('Setoran'), findsOneWidget);
    await tester.tap(find.byKey(RoleTransactionMenu.setoranKey));
    await tester.pumpAndSettle();

    // The form now opens as a panel over the shell rather than as its own
    // page, so what proves it arrived is the form itself, not the stub route.
    expect(find.text('PILIH NASABAH'), findsOneWidget);
    final transactionMenu = tester.widget<RoleMenuRow>(find.byKey(
      RoleTransactionMenu.headerKey,
      skipOffstage: false,
    ));
    expect(transactionMenu.selected, isTrue);
    final setoran = tester.widget<RoleMenuRow>(find.byKey(
      RoleTransactionMenu.setoranKey,
      skipOffstage: false,
    ));
    expect(setoran.selected, isTrue);

    // Closed the way a user closes a panel. `router.pop()` would reach past
    // it: the panel is pushed straight onto the Navigator and never enters
    // go_router's match list, so GoRouter would pop the shell underneath.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    final inactiveMenu =
        tester.widget<RoleMenuRow>(find.byKey(RoleTransactionMenu.headerKey));
    expect(inactiveMenu.selected, isFalse);
    expect(
      tester
          .widget<RoleMenuRow>(find.byKey(RoleTransactionMenu.setoranKey))
          .selected,
      isFalse,
    );
  });

  testWidgets('loads membership status after an initial shell state',
      (tester) async {
    final approval = TestNasabahApprovalNotifier(
      initialState: const NasabahApprovalInitial(),
    );

    await mount(tester, session('nasabah'), approvalNotifier: approval);

    expect(approval.loadCalls, [false]);
  });

  testWidgets('pending membership shows status home with only Home and Profile',
      (tester) async {
    final approval = TestNasabahApprovalNotifier(
        initialState: const NasabahApprovalLoaded([pending]));
    await mount(tester, session('nasabah'), approvalNotifier: approval);
    expect(labels(tester), ['Beranda', 'Profil']);
    expect(find.text('Bank Sampah Melati'), findsWidgets);
    expect(find.text('Pengajuan dikirim'), findsOneWidget);
    expect(find.text('Menunggu verifikasi pengurus'), findsOneWidget);
    expect(find.text('body:/home'), findsNothing);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('body:/profile'), findsOneWidget);
    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();
    expect(approval.loadCalls, [true]);
    await tester.tap(find.text('Lihat detail pengajuan'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('application details'), findsOneWidget);
  });

  testWidgets('a rejected application explains the next step', (tester) async {
    await mount(tester, session('nasabah'),
        approvalState: const NasabahApprovalLoaded([
          NasabahMembershipEntity(
            id: 'application-1',
            bankSampahId: 'bank-1',
            bankSampahNama: 'Bank Sampah Melati',
            bankSampahKota: 'Bandung',
            bankSampahAlamat: 'Jl. Melati',
            status: MembershipStatus.rejected,
            isActive: false,
          ),
        ]));
    expect(labels(tester), ['Beranda', 'Profil']);
    expect(find.text('Pengajuan belum disetujui'), findsOneWidget);
    expect(find.textContaining('ajukan banding'), findsOneWidget);
  });

  testWidgets('pending membership cannot open an old Tabungan route',
      (tester) async {
    final router = await mount(tester, session('nasabah'),
        approvalState: const NasabahApprovalLoaded([pending]));
    router.go('/history');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/home');
    expect(find.text('body:/history'), findsNothing);
  });

  testWidgets('status error offers retry without exposing savings',
      (tester) async {
    await mount(tester, session('nasabah'),
        approvalState: const NasabahApprovalError('Tidak dapat memuat status'));
    expect(labels(tester), ['Beranda', 'Profil']);
    expect(find.text('Tidak dapat memuat status'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(find.text('body:/home'), findsNothing);
  });

  testWidgets('approval restores full navigation after refreshing the status',
      (tester) async {
    final approval = TestNasabahApprovalNotifier(
        initialState: const NasabahApprovalLoaded([pending]));
    await mount(tester, session('nasabah'), approvalNotifier: approval);
    approval.setStateForTest(const NasabahApprovalLoaded([approved]));
    await tester.pumpAndSettle();
    expect(labels(tester), ['Beranda', 'Tabungan', 'Jadwal', 'Profil']);
    expect(find.text('body:/home'), findsOneWidget);
  });

  testWidgets(
      'a deep link opened while approval status is still loading is not '
      'discarded once membership turns out to be active', (tester) async {
    final approval = TestNasabahApprovalNotifier(
        initialState: const NasabahApprovalLoading());
    final router = await mount(tester, session('nasabah'),
        initialLocation: '/history', approvalNotifier: approval, settle: false);
    approval.setStateForTest(const NasabahApprovalLoaded([approved]));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/history');
    expect(find.text('body:/history'), findsOneWidget);
  });

  testWidgets('customer history selection updates the shell and selected tab', (
    tester,
  ) async {
    final router = await mount(tester, session('nasabah'));
    expect(find.text('Tabungan'), findsOneWidget);
    await tester.tap(find.text('Tabungan'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/history');
    expect(find.text('body:/history'), findsOneWidget);
    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      1,
    );
  });

  for (final role in ['unknown', 'superadmin']) {
    testWidgets('$role must not inherit customer or staff navigation', (
      tester,
    ) async {
      await mount(tester, session(role));
      expect(find.byType(BottomNavigationBar), findsNothing);
    });
  }

  testWidgets('staff logout returns to login instead of the signed-out shell', (
    tester,
  ) async {
    final auth = authNotifierIn(session('pengelola'));
    final router =
        await mount(tester, session('pengelola'), authNotifier: auth);

    auth.setStateForTest(AuthenticationLoading());
    await tester.pump();
    auth.setStateForTest(Unauthenticated());
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/login');
    expect(find.text('login page'), findsOneWidget);
    expect(find.text('Silakan masuk sebagai nasabah.'), findsNothing);
  });

  for (final state in <AuthenticationStates>[
    AuthenticationLoading(),
    Unauthenticated(),
  ]) {
    testWidgets(
        '${state.runtimeType} shows a blank shell, not the nasabah message',
        (tester) async {
      await mount(tester, state);

      expect(find.text('Silakan masuk sebagai nasabah.'), findsNothing);
    });
  }

  testWidgets('signed-out session cannot display privileged navigation', (
    tester,
  ) async {
    await mount(tester, Unauthenticated());
    expect(find.byType(BottomNavigationBar), findsNothing);
  });

  testWidgets('an active nasabah opens the schedule tab', (tester) async {
    await mount(tester, session('nasabah'), initialLocation: '/schedule');

    expect(find.text('body:/schedule'), findsOneWidget);
    expect(find.text('Kembali ke Beranda'), findsNothing);
  });

  testWidgets('a branch outside the role navigation offers a way back home',
      (tester) async {
    final router =
        await mount(tester, session('pengelola'), initialLocation: '/history');

    expect(find.text('body:/history'), findsNothing);
    await tester.tap(find.text('Kembali ke Beranda'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/home');
    expect(find.text('body:/home'), findsOneWidget);
  });

  testWidgets('staff may open their profile outside the five destinations',
      (tester) async {
    await mount(tester, session('pengelola'), initialLocation: '/profile');

    expect(find.text('body:/profile'), findsOneWidget);
    expect(find.text('Kembali ke Beranda'), findsNothing);
  });
}
