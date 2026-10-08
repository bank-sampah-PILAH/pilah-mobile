import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/app_environment.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/core/router/app_router_config.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_cubit.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/riwayat_pencairan_filter.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/pencairan/presentation/blocs/riwayat_pencairan_cubit.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';
import '../../support/approved_membership.dart';

class _Auth extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

class _Environment extends Mock implements AppEnvironment {}

class _PayoutUseCases extends Mock implements PencairanUseCases {}

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
  setUpAll(() => registerFallbackValue(const RiwayatPencairanFilter()));
  late _Repository repository;
  late _Auth auth;
  late _PayoutUseCases payoutUseCases;
  late StreamController<AuthenticationStates> states;
  late NasabahApprovalCubit approval;
  setUp(() {
    repository = _Repository();
    approval = registerApprovedMembership();
    auth = _Auth();
    payoutUseCases = _PayoutUseCases();
    when(() => payoutUseCases.getRiwayat(any())).thenAnswer(
      (_) async => const Right<NetworkException, List<Pencairan>>([]),
    );
    states = StreamController<AuthenticationStates>.broadcast();
    di.registerSingleton<NasabahRepository>(repository);
    final environment = _Environment();
    when(() => environment.supportsDemoLogin).thenReturn(false);
    di.registerSingleton<AppEnvironment>(environment);
    di.registerSingleton<InviteTokenStore>(InviteTokenStore());
    di.registerFactory<RiwayatPencairanCubit>(
      () => RiwayatPencairanCubit(payoutUseCases),
    );
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
    await unregisterApprovedMembership(approval);
    di<InviteTokenStore>().dispose();
    await di.unregister<InviteTokenStore>();
    await di.unregister<RiwayatPencairanCubit>();
    await di.unregister<AppEnvironment>();
    await di.unregister<NasabahRepository>();
  });
  Future<void> open(WidgetTester tester, String path) async {
    // These tests assert on the nasabah bottom navigation bar, so the window
    // has to stay in the compact width class; the 800x600 test default is
    // classified as a tablet and renders a navigation rail instead. The width
    // is kept just under the boundary rather than at a phone width so the rest
    // of the layout these tests inspect is disturbed as little as possible.
    tester.view.physicalSize = const Size(599, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    router.go(path);
    await tester.pumpWidget(BlocProvider<AuthenticationBloc>.value(
      value: auth,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'balance card opens Tabungan on Setoran and keeps membership while paging',
      (tester) async {
    await open(tester, '/dashboard');
    expect(find.text('Riwayat Aktivitas'), findsNothing);
    expect(find.text('Pencairan'), findsNothing);
    await tester.ensureVisible(find.text('Rp 12.500,50'));
    await tester.tap(find.text('Rp 12.500,50'));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.last.matchedLocation,
        '/riwayat');
    expect(
        DefaultTabController.of(tester.element(find.byType(TabBar))).index, 0);
    expect(find.text('Riwayat Setoran'), findsOneWidget);
    await tester.tap(find.text('Muat Lagi'));
    await tester.pumpAndSettle();
    expect(repository.requests, [('member-b', 1), ('member-b', 2)]);
    expect(find.text('+ Rp 1'), findsOneWidget);
    expect(find.text('+ Rp 2'), findsOneWidget);
    states.add(Unauthenticated());
    await tester.pumpAndSettle();
    expect(find.text('+ Rp 1'), findsNothing);
    expect(find.text('+ Rp 2'), findsNothing);
    expect(router.routeInformationProvider.value.uri.path, LoginPage.route);
  });

  testWidgets('pencairan tab is selectable and can be deep-linked',
      (tester) async {
    await open(tester, '/riwayat?keanggotaan_id=member-b&filter=pencairan');

    expect(
        DefaultTabController.of(tester.element(find.byType(TabBar))).index, 1);
    expect(find.text('Riwayat Pencairan'), findsOneWidget);
    expect(find.text('Belum ada riwayat pencairan'), findsOneWidget);
    verify(() => payoutUseCases.getRiwayat(any())).called(1);

    await tester.tap(find.text('Setoran'));
    await tester.pumpAndSettle();
    expect(find.text('Riwayat Setoran'), findsOneWidget);
  });

  testWidgets('direct history resolves the active membership', (tester) async {
    await open(tester, '/riwayat');
    expect(find.text('+ Rp 1'), findsOneWidget);
    expect(repository.requests, [('member-b', 1)]);
  });

  testWidgets('customer navigation opens savings and profile routes',
      (tester) async {
    await open(tester, '/dashboard');
    final bar = find.byType(BottomNavigationBar);
    expect(bar, findsOneWidget);
    await tester.tap(find.descendant(of: bar, matching: find.text('Tabungan')));
    await tester.pumpAndSettle();
    expect(find.text('+ Rp 1'), findsOneWidget);
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
    expect(find.text('Siti'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
