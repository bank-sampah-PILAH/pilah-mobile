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
import 'package:pilah_mobile/features/main/presentation/pages/main_page.dart';

class MockAuth extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

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
    {Stream<AuthenticationStates>? states}) async {
  final auth = MockAuth();
  when(() => auth.state).thenReturn(state);
  when(() => auth.stream).thenAnswer((_) => const Stream.empty());
  if (states != null) whenListen(auth, states, initialState: state);
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => MainPage(navigationShell: shell),
        branches: [
          for (final path in [
            '/home',
            '/customers',
            '/prices',
            '/reports',
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
  await tester.pumpAndSettle();
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
    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();
    states.add(session('pengelola'));
    await tester.pumpAndSettle();
    expect(labels(tester), ['Dashboard', 'Nasabah', 'Harga', 'Laporan']);
    expect(router.routeInformationProvider.value.uri.path, '/home');
    expect(find.text('body:/history'), findsNothing);
  });
  testWidgets(
    'nasabah receives customer destinations rather than staff menus',
    (tester) async {
      await mount(tester, session('nasabah'));
      expect(labels(tester), ['Beranda', 'Riwayat', 'Bank Sampah', 'Profil']);
      expect(find.text('Nasabah'), findsNothing);
      expect(find.text('Laporan'), findsNothing);
    },
  );

  for (final role in ['pengelola', 'pengelola_induk']) {
    testWidgets('$role retains the staff navigation', (tester) async {
      await mount(tester, session(role));
      expect(labels(tester), ['Dashboard', 'Nasabah', 'Harga', 'Laporan']);
    });
  }

  testWidgets('customer history selection updates the shell and selected tab', (
    tester,
  ) async {
    final router = await mount(tester, session('nasabah'));
    expect(find.text('Riwayat'), findsOneWidget);
    await tester.tap(find.text('Riwayat'));
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

  testWidgets('signed-out session cannot display privileged navigation', (
    tester,
  ) async {
    await mount(tester, Unauthenticated());
    expect(find.byType(BottomNavigationBar), findsNothing);
  });
}
