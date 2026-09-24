import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/riwayat/presentation/pages/nasabah_history_screen.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/beranda/presentation/pages/beranda_nasabah_page.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';

class _Auth extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

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

  @override
  Future<NasabahHistory> history(String membershipId, {int page = 1}) async {
    pages.add((membershipId, page));
    return NasabahHistory([
      NasabahActivity('t$page', DateTime(2026, 9, 23), 'setoran', '$page.00')
    ], page == 1);
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
  late _Auth auth;
  setUp(() {
    repository = _Repository();
    auth = _Auth();
    di.registerSingleton<NasabahRepository>(repository);
  });
  tearDown(() async {
    await di.unregister<NasabahRepository>();
    await auth.close();
  });
  Future<void> open(WidgetTester tester,
      {Stream<AuthenticationStates>? states}) async {
    whenListen(auth, states ?? const Stream<AuthenticationStates>.empty(),
        initialState: session('Siti'));
    final router = GoRouter(initialLocation: '/dashboard', routes: [
      GoRoute(
          path: '/dashboard', builder: (_, __) => const BerandaNasabahPage()),
      GoRoute(
          path: '/riwayat',
          builder: (_, state) => NasabahHistoryScreen(
                membershipId: state.uri.queryParameters['keanggotaan_id'],
              )),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(BlocProvider<AuthenticationBloc>.value(
        value: auth, child: MaterialApp.router(routerConfig: router)));
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
    await tester.ensureVisible(find.text('Riwayat Aktivitas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Riwayat Aktivitas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Muat Lagi'));
    await tester.pumpAndSettle();
    expect(repository.pages, [('member-b', 1), ('member-b', 2)]);
    expect(find.text('Rp 2'), findsOneWidget);
    expect(find.text('Rp 1'), findsOneWidget);
    expect(find.text('Muat Lagi'), findsNothing);
  });

  testWidgets('switching account discards an earlier pending home response',
      (tester) async {
    final states = StreamController<AuthenticationStates>();
    addTearDown(states.close);
    final old = Completer<NasabahHome>();
    repository.pending = old;
    await open(tester, states: states.stream);
    repository.pending = null;
    repository.fail = true;
    states.add(session('Budi'));
    await tester.pumpAndSettle();
    old.complete(await PreviewNasabahRepository().home());
    await tester.pumpAndSettle();
    expect(find.text('Rp 12.500,50'), findsNothing);
    expect(find.text('Selamat datang, Budi'), findsOneWidget);
  });
  testWidgets('open details hide private data after logout', (tester) async {
    final states = StreamController<AuthenticationStates>();
    addTearDown(states.close);
    await open(tester, states: states.stream);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Saldo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saldo'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada perubahan saldo.'), findsOneWidget);
    states.add(Unauthenticated());
    await tester.pumpAndSettle();
    expect(find.text('Rp 12.500,50'), findsNothing);
    expect(find.text('Sesi berubah. Tutup detail dan masuk kembali.'),
        findsOneWidget);
  });
}
