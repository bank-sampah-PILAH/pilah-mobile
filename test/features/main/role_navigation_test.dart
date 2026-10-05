import 'package:bloc_test/bloc_test.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_cubit.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_state.dart';
import 'package:pilah_mobile/features/main/presentation/pages/main_page.dart';
import 'package:pilah_mobile/services/di.dart';

class MockAuth extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

class MockApproval extends MockCubit<NasabahApprovalState>
    implements NasabahApprovalCubit {}

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
    {Stream<AuthenticationStates>? states,
    NasabahApprovalState approvalState =
        const NasabahApprovalLoaded([approved]),
    Stream<NasabahApprovalState>? approvalStates,
    MockApproval? approvalCubit,
    String initialLocation = '/home',
    bool settle = true}) async {
  final approval = approvalCubit ?? MockApproval();
  when(() => approval.load(silent: any(named: 'silent')))
      .thenAnswer((_) async {});
  whenListen(
      approval, approvalStates ?? const Stream<NasabahApprovalState>.empty(),
      initialState: approvalState);
  di.registerFactory<NasabahApprovalCubit>(() => approval);
  addTearDown(() async {
    await di.unregister<NasabahApprovalCubit>();
    await approval.close();
  });
  final auth = MockAuth();
  when(() => auth.state).thenReturn(state);
  when(() => auth.stream).thenAnswer((_) => const Stream.empty());
  if (states != null) whenListen(auth, states, initialState: state);
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => MainPage(navigationShell: shell),
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
  addTearDown(auth.close);
  await tester.pumpWidget(
    BlocProvider<AuthenticationBloc>.value(
      value: auth,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
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
    final states = StreamController<AuthenticationStates>.broadcast();
    addTearDown(states.close);
    final router =
        await mount(tester, session('nasabah'), states: states.stream);
    await tester.tap(find.text('Tabungan'));
    await tester.pumpAndSettle();
    states.add(session('pengelola'));
    await tester.pumpAndSettle();
    expect(labels(tester), [
      'Dashboard',
      'Nasabah',
      'Harga',
      'Laporan',
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
      expect(find.text('Laporan'), findsNothing);
    },
  );

  for (final role in ['pengelola', 'pengelola_induk']) {
    testWidgets('$role retains the staff navigation', (tester) async {
      await mount(tester, session(role));
      expect(labels(tester), [
        'Dashboard',
        'Nasabah',
        'Harga',
        'Laporan',
        'Jadwal',
      ]);
    });
  }

  testWidgets('pending membership shows status home with only Home and Profile',
      (tester) async {
    final approval = MockApproval();
    await mount(tester, session('nasabah'),
        approvalState: const NasabahApprovalLoaded([pending]),
        approvalCubit: approval);
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
    verify(() => approval.load(silent: true)).called(1);
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
    final updates = StreamController<NasabahApprovalState>.broadcast();
    addTearDown(updates.close);
    await mount(tester, session('nasabah'),
        approvalState: const NasabahApprovalLoaded([pending]),
        approvalStates: updates.stream);
    updates.add(const NasabahApprovalLoaded([approved]));
    await tester.pumpAndSettle();
    expect(labels(tester), ['Beranda', 'Tabungan', 'Jadwal', 'Profil']);
    expect(find.text('body:/home'), findsOneWidget);
  });

  testWidgets(
      'a deep link opened while approval status is still loading is not '
      'discarded once membership turns out to be active', (tester) async {
    final approvalStates = StreamController<NasabahApprovalState>.broadcast();
    addTearDown(approvalStates.close);
    final router = await mount(tester, session('nasabah'),
        initialLocation: '/history',
        approvalState: const NasabahApprovalLoading(),
        approvalStates: approvalStates.stream,
        settle: false);
    approvalStates.add(const NasabahApprovalLoaded([approved]));
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
    final states = StreamController<AuthenticationStates>.broadcast();
    addTearDown(states.close);
    final router =
        await mount(tester, session('pengelola'), states: states.stream);

    states.add(AuthenticationLoading());
    await tester.pump();
    states.add(Unauthenticated());
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/login');
    expect(find.text('login page'), findsOneWidget);
    expect(find.text('Silakan masuk sebagai nasabah.'), findsNothing);
  });

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
