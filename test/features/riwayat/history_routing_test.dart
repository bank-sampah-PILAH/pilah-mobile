import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/router/app_router_config.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';

class _Auth extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

class _Repository extends PreviewNasabahRepository {
  final requests = <(String, int)>[];
  @override
  Future<NasabahHome> home({String? membershipId}) =>
      super.home(membershipId: 'member-b');
  @override
  Future<NasabahHistory> history(String membershipId, {int page = 1}) async {
    requests.add((membershipId, page));
    return NasabahHistory([
      NasabahActivity('t$page', DateTime(2026, 9, 23), 'setoran', '$page.00'),
    ], page == 1);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final router = AppRouterConfig.getRouter();
  tearDownAll(router.dispose);
  late _Repository repository;
  late _Auth auth;
  late StreamController<AuthenticationStates> states;
  setUp(() {
    repository = _Repository();
    auth = _Auth();
    states = StreamController<AuthenticationStates>.broadcast();
    di.registerSingleton<NasabahRepository>(repository);
    di.registerSingleton<InviteTokenStore>(InviteTokenStore());
    whenListen(auth, states.stream,
        initialState: Authenticated(
          authEntity: const AuthEntity(
              id: 'siti',
              name: 'Siti',
              email: 'siti@example.test',
              photoUrl: '',
              token: 'test',
              role: 'nasabah',
              nextStep: 'nasabah_dashboard'),
        ));
  });
  tearDown(() async {
    await states.close();
    await auth.close();
    di<InviteTokenStore>().dispose();
    await di.unregister<InviteTokenStore>();
    await di.unregister<NasabahRepository>();
  });
  Future<void> open(WidgetTester tester, String path) async {
    router.go(path);
    await tester.pumpWidget(BlocProvider<AuthenticationBloc>.value(
      value: auth,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'home opens a history route with its membership and appends pages',
      (tester) async {
    await open(tester, '/dashboard');
    await tester.ensureVisible(find.text('Riwayat Aktivitas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Riwayat Aktivitas'));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.last.matchedLocation,
        '/riwayat');
    await tester.tap(find.text('Muat Lagi'));
    await tester.pumpAndSettle();
    expect(repository.requests, [('member-b', 1), ('member-b', 2)]);
    expect(find.text('Rp 1'), findsOneWidget);
    expect(find.text('Rp 2'), findsOneWidget);
    states.add(Unauthenticated());
    await tester.pumpAndSettle();
    expect(find.text('Rp 1'), findsNothing);
    expect(find.text('Rp 2'), findsNothing);
    expect(find.text('Silakan masuk sebagai nasabah.'), findsOneWidget);
  });

  testWidgets('direct history resolves the active membership', (tester) async {
    await open(tester, '/riwayat');
    expect(find.text('Rp 1'), findsOneWidget);
    expect(repository.requests, [('member-b', 1)]);
  });

  testWidgets('customer navigation opens real history bank and profile routes',
      (tester) async {
    await open(tester, '/dashboard');
    final bar = find.byType(BottomNavigationBar);
    expect(bar, findsOneWidget);
    await tester.tap(find.descendant(of: bar, matching: find.text('Riwayat')));
    await tester.pumpAndSettle();
    expect(find.text('Rp 1'), findsOneWidget);
    await tester
        .tap(find.descendant(of: bar, matching: find.text('Bank Sampah')));
    await tester.pumpAndSettle();
    expect(find.text('Jl. Melati'), findsOneWidget);
    await tester.tap(find.descendant(of: bar, matching: find.text('Profil')));
    await tester.pumpAndSettle();
    expect(find.text('preview@example.test'), findsOneWidget);
    expect(tester.widget<BottomNavigationBar>(bar).currentIndex, 3);
  });

  testWidgets(
      'customer direct link to staff customers is redirected before loading',
      (tester) async {
    await open(tester, '/nasabah');
    expect(router.routeInformationProvider.value.uri.path, '/dashboard');
    expect(find.text('Selamat datang, Siti'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
