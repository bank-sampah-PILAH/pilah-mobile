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
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_approval_provider.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/riwayat_pencairan_filter.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/riwayat/data/datasources/riwayat_remote_data_source.dart';
import 'package:pilah_mobile/features/riwayat/data/repositories/riwayat_repository_impl.dart';
import 'package:pilah_mobile/features/riwayat/domain/entities/riwayat_entities.dart';
import 'package:pilah_mobile/features/riwayat/domain/repositories/riwayat_repository.dart';
import 'package:pilah_mobile/features/riwayat/domain/use_cases/riwayat_use_cases.dart';
import 'package:pilah_mobile/features/riwayat/presentation/providers/riwayat_history_provider.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/features/pengumuman/data/nasabah_pengumuman_repository.dart';
import 'package:pilah_mobile/services/di.dart';
import '../../support/approved_membership.dart';
import '../../support/auth_support.dart';
import '../../support/nasabah_approval_support.dart';
import '../../support/stub_api.dart';

class _Environment extends Mock implements AppEnvironment {}

class _PayoutUseCases extends Mock implements PencairanUseCases {}

class _Repository extends PreviewNasabahRepository {
  @override
  Future<NasabahHome> home({String? membershipId}) =>
      super.home(membershipId: 'member-b');
}

/// Serves the routed history screen: the same fixture rows the old
/// repository override held, now one layer down, behind the cubit.
class _RiwayatRemoteSource implements RiwayatRemoteDataSource {
  _RiwayatRemoteSource(
    Object _, {
    List<List<NasabahActivity>> pages = const [],
  }) : pagesList = pages;

  final List<List<NasabahActivity>> pagesList;
  final requests = <(String, int)>[];

  @override
  Future<RiwayatHistory> history(String membershipId, {int page = 1}) async {
    requests.add((membershipId, page));
    final rows = pagesList.isNotEmpty && pagesList.length >= page
        ? pagesList[page - 1]
        : const <NasabahActivity>[];
    return RiwayatHistory(
      List.of(rows),
      page <= pagesList.length - 1,
    );
  }

  @override
  Future<RiwayatSetoranDetail> setoranDetail(
          String membershipId, String transactionId) =>
      throw UnsupportedError('No detail in this test');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final router = AppRouterConfig.getRouter();
  tearDownAll(router.dispose);
  setUpAll(() => registerFallbackValue(const RiwayatPencairanFilter()));
  late _Repository repository;
  late _RiwayatRemoteSource riwayatSource;
  late TestAuthenticationNotifier auth;
  late _PayoutUseCases payoutUseCases;

  late TestNasabahApprovalNotifier approval;
  setUp(() {
    repository = _Repository();
    approval = buildApprovedMembershipNotifier();
    auth = authNotifierIn(
      Authenticated(
        authEntity: const AuthEntity(
          id: 'siti',
          name: 'Siti',
          email: 'siti@example.test',
          photoUrl: '',
          token: 'test',
          role: 'nasabah',
          nextStep: 'nasabah_dashboard',
        ),
      ),
    );
    payoutUseCases = _PayoutUseCases();
    when(() => payoutUseCases.getRiwayat(any())).thenAnswer(
      (_) async => const Right<NetworkException, List<Pencairan>>([]),
    );
    di.registerSingleton<NasabahRepository>(repository);
    // The beranda page resolves the pengumuman section from the service
    // locator, so the stub API behind it needs the same registration.
    final pengumumanApi = StubApi();
    pengumumanApi.on('GET', '/api/v1/nasabah/me/pengumuman/beranda',
        json: {'items': [], 'unread_count': 0});
    di.registerSingleton<NasabahPengumumanRepository>(
        NasabahPengumumanRepository(pengumumanApi.network));
    addTearDown(() => di.unregister<NasabahPengumumanRepository>());
    // Back the history provider with the preview repository so rows render.
    riwayatSource = _RiwayatRemoteSource(
      repository,
      pages: [
        [
          NasabahActivity('t1', DateTime(2026, 9, 23), 'setoran', '1.00'),
          NasabahActivity('t2', DateTime(2026, 9, 22), 'setoran', '2.00'),
        ],
        [
          NasabahActivity('t3', DateTime(2026, 9, 21), 'setoran', '3.00'),
        ],
      ],
    );
    di.registerFactory<RiwayatRemoteDataSource>(() => riwayatSource);
    di.registerLazySingleton<RiwayatRepository>(
      () => RiwayatRepositoryImpl(di<RiwayatRemoteDataSource>()),
    );
    final environment = _Environment();
    when(() => environment.supportsDemoLogin).thenReturn(false);
    di.registerSingleton<AppEnvironment>(environment);
    di.registerSingleton<InviteTokenStore>(InviteTokenStore());
    di.registerFactory<PencairanUseCases>(() => payoutUseCases);
  });
  tearDown(() async {
    di<InviteTokenStore>().dispose();
    await di.unregister<InviteTokenStore>();
    await di.unregister<PencairanUseCases>();
    await di.unregister<RiwayatRepository>();
    await di.unregister<RiwayatRemoteDataSource>();
    await di.unregister<AppEnvironment>();
    await di.unregister<NasabahRepository>();
  });
  Future<void> open(WidgetTester tester, String path) async {
    router.go(path);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        nasabahApprovalProvider.overrideWith(() => approval),
        authenticationProvider.overrideWith(() => auth),
        riwayatHistoryProvider.overrideWith(
          () => RiwayatHistoryNotifier(
            GetRiwayatHistoryUseCase(di<RiwayatRepository>()),
            GetRiwayatSetoranDetailUseCase(di<RiwayatRepository>()),
          ),
        ),
      ],
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
    expect(riwayatSource.requests, [('member-b', 1), ('member-b', 2)]);
    expect(find.text('+ Rp 1'), findsOneWidget);
    expect(find.text('+ Rp 2'), findsOneWidget);
    auth.setStateForTest(Unauthenticated());
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
    expect(riwayatSource.requests, [('member-b', 1)]);
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
