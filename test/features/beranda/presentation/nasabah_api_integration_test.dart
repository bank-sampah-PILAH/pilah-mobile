import 'dart:async';
import '../../../support/stub_api.dart';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';

import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import '../../../support/fake_riwayat.dart';
import '../../../support/auth_support.dart';
import 'package:pilah_mobile/features/beranda/presentation/pages/beranda_nasabah_page.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_page_result.dart';
import 'package:pilah_mobile/features/jadwal/domain/repositories/jadwal_repository.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/riwayat_pencairan_filter.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/riwayat/presentation/pages/nasabah_history_screen.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/features/pengumuman/data/nasabah_pengumuman_repository.dart';
import 'package:pilah_mobile/services/di.dart';

class _JadwalRepository extends Mock implements JadwalRepository {}

class _PayoutUseCases extends Mock implements PencairanUseCases {}

class _Repository extends PreviewNasabahRepository {
  final selections = <String?>[];
  final pages = <(String, int)>[];
  bool fail = false;
  bool choose = false;
  Completer<NasabahHome>? pending;
  @override
  Future<NasabahHome> home({String? membershipId}) async {
    selections.add(membershipId);
    if (pending != null) return pending!.future;
    if (fail) throw const NasabahApiException('Akses belum tersedia.');
    if (choose && membershipId == null) {
      throw const NasabahApiException('Pilih bank sampah Anda.',
          choices: [MembershipChoice('member-b', 'Mawar')]);
    }
    return super.home(membershipId: membershipId);
  }
}

Authenticated session(String id) => Authenticated(
    authEntity: AuthEntity(
        id: id,
        name: id,
        email: '$id@example.test',
        photoUrl: '',
        token: id,
        role: 'nasabah',
        nextStep: 'nasabah_dashboard'));

void main() {
  late _Repository repository;
  late FakeRiwayatRemoteDataSource riwayat;
  late TestAuthenticationNotifier auth;
  late _JadwalRepository jadwalRepository;
  late _PayoutUseCases payoutUseCases;
  setUpAll(() => registerFallbackValue(const RiwayatPencairanFilter()));
  setUp(() {
    repository = _Repository();
    riwayat = FakeRiwayatRemoteDataSource(pages: [
      [
        NasabahActivity('t1', DateTime(2026, 9, 23), 'setoran', '12500.00'),
        NasabahActivity('t2', DateTime(2026, 9, 22), 'setoran', '20000.00'),
      ],
      [
        NasabahActivity('t3', DateTime(2026, 9, 21), 'setoran', '30000.00'),
      ],
    ]);
    auth = authNotifierIn(session('Siti'));
    jadwalRepository = _JadwalRepository();
    payoutUseCases = _PayoutUseCases();
    when(() => jadwalRepository.getJadwal(page: 1, date: null)).thenAnswer(
      (_) async => Right(const JadwalPageResult(
        items: [],
        totalCount: 0,
        hasMore: false,
      )),
    );
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
    di.registerSingleton<JadwalRepository>(jadwalRepository);
    di.registerFactory<PencairanUseCases>(() => payoutUseCases);
    registerFakeRiwayat(riwayat);
  });
  tearDown(() async {
    await di.unregister<PencairanUseCases>();
    await unregisterFakeRiwayat();
    await di.unregister<NasabahRepository>();
    await di.unregister<JadwalRepository>();
  });
  Future<void> open(WidgetTester tester) async {
    final router = GoRouter(initialLocation: '/dashboard', routes: [
      GoRoute(
          path: '/dashboard', builder: (_, __) => const BerandaNasabahPage()),
      GoRoute(
          path: '/riwayat',
          builder: (_, state) => NasabahHistoryScreen(
                membershipId: state.uri.queryParameters['keanggotaan_id'],
                initialPencairan:
                    state.uri.queryParameters['filter'] == 'pencairan',
              )),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(withAuthenticationProvider(
      auth,
      MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
  }

  testWidgets('loading then server balance works without login bank status',
      (tester) async {
    repository.pending = Completer<NasabahHome>();
    await open(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repository.pending!.complete(await PreviewNasabahRepository().home());
    await tester.pumpAndSettle();
    expect(find.text('Rp 12.500,50'), findsOneWidget);
  });

  testWidgets('denied membership shows no balance and supports retry',
      (tester) async {
    repository.fail = true;
    await open(tester);
    await tester.pumpAndSettle();
    expect(find.text('Rp 12.500,50'), findsNothing);
    expect(find.text('Akses belum tersedia.'), findsOneWidget);
    repository.fail = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Rp 12.500,50'), findsOneWidget);
  });

  testWidgets('select membership and retain it through paginated history',
      (tester) async {
    repository.choose = true;
    await open(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mawar'));
    await tester.pumpAndSettle();
    expect(repository.selections, [null, 'member-b']);
    await tester.ensureVisible(find.text('Rp 12.500,50'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rp 12.500,50'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Muat Lagi'));
    await tester.pumpAndSettle();
    expect(riwayat.requests, [('member-b', 1), ('member-b', 2)]);
    expect(find.textContaining('30.000'), findsOneWidget);
    expect(find.text('Muat Lagi'), findsNothing);
  });

  testWidgets('switching account discards an earlier pending home response',
      (tester) async {
    final old = Completer<NasabahHome>();
    repository.pending = old;
    await open(tester);
    repository.pending = null;
    repository.fail = true;
    auth.setStateForTest(session('Budi'));
    await tester.pumpAndSettle();
    old.complete(await PreviewNasabahRepository().home());
    await tester.pumpAndSettle();
    expect(find.text('Rp 12.500,50'), findsNothing);
    expect(find.text('Budi'), findsOneWidget);
  });
  testWidgets('Tabungan hides private data after logout', (tester) async {
    await open(tester);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Rp 12.500,50'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rp 12.500,50'));
    await tester.pumpAndSettle();
    expect(find.text('Tabungan Saya'), findsOneWidget);
    auth.setStateForTest(Unauthenticated());
    await tester.pumpAndSettle();
    expect(find.text('Rp 12.500,50'), findsNothing);
    expect(find.text('Silakan masuk sebagai nasabah.'), findsOneWidget);
  });
}
