import 'package:flutter/material.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/logout_events.dart';
import 'package:pilah_mobile/features/superadmin/presentation/cubit/superadmin_cubit.dart';
import 'package:pilah_mobile/features/superadmin/presentation/pages/superadmin_dashboard_screen.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';
import '../../../../support/superadmin_support.dart';

const _path = '/api/v1/superadmin/bank-sampah';

class _FakeAuthEvent extends Fake implements AuthenticationEvent {}

void main() {
  late StubApi api;
  late MockAuthBloc auth;

  setUpAll(() => registerFallbackValue(_FakeAuthEvent()));

  setUp(() {
    api = StubApi();
    di.registerFactory<SuperadminCubit>(() => buildSuperadminCubit(api));
    auth = authBlocIn(Authenticated(authEntity: testAuth(role: 'superadmin')));
  });

  tearDown(() => di.unregister<SuperadminCubit>());

  Future<void> openScreen(WidgetTester tester) async {
    await pumpRouted(
      tester,
      BlocProvider<AuthenticationBloc>.value(
        value: auth,
        // A non-const instance, so the widget's constructor itself runs.
        // ignore: prefer_const_constructors
        child: SuperAdminDashboardScreen(),
      ),
      extraRoutes: ['/login'],
      size: const Size(800, 1800),
    );
    await tester.pumpAndSettle();
  }

  void stubTabs({List<Map<String, dynamic>>? pending}) {
    api.on('GET', _path, json: {
      'results': pending ??
          [
            bankRow('1', nama: 'Bank Melati', created: '2026-09-01T10:00:00Z'),
            bankRow('2',
                nama: 'Bank Tanpa Tanggal',
                created: null,
                withPengelola: false),
          ],
    });
  }

  testWidgets('lists the pending submissions with their details',
      (tester) async {
    stubTabs();
    await openScreen(tester);

    expect(find.text('Manajemen Bank Sampah'), findsOneWidget);
    expect(find.text('Bank Melati'), findsOneWidget);
    expect(find.text('Budi (Ketua)'), findsOneWidget);
    expect(find.text('- (Ketua)'), findsOneWidget);
    expect(find.text('Jl. Melati 1'), findsWidgets);
    expect(find.text('Diajukan: -'), findsOneWidget);
    expect(find.text('Menunggu: 0 hari'), findsOneWidget);
    expect(find.text('PENDING'), findsNWidgets(2));
  });

  testWidgets('approving asks first, posts and reports success',
      (tester) async {
    stubTabs();
    api.on('POST', '$_path/1/approve', json: {});
    await openScreen(tester);
    api.latency = const Duration(milliseconds: 200);

    await tester.tap(find.text('Setujui').first);
    await tester.pumpAndSettle();
    expect(find.text('Setujui Bank Sampah?'), findsOneWidget);
    // The backend no longer lists the bank once it is decided.
    stubTabs(pending: [bankRow('2', nama: 'Bank Lain')]);
    await tester.tap(find.text('Ya, Setujui'));
    await pumpToast(tester);

    expect(api.requests.any((r) => r.path == '$_path/1/approve'), isTrue);
    expect(find.text('Bank Melati berhasil disetujui.'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('rejecting asks first and reports the rejection', (tester) async {
    stubTabs();
    api.on('POST', '$_path/1/reject', json: {});
    await openScreen(tester);
    api.latency = const Duration(milliseconds: 200);

    await tester.tap(find.text('Tolak').first);
    await tester.pumpAndSettle();
    expect(find.text('Tolak Pendaftaran?'), findsOneWidget);
    stubTabs(pending: [bankRow('2', nama: 'Bank Lain')]);
    await tester.tap(find.text('Ya, Tolak'));
    await pumpToast(tester);

    expect(find.text('Pendaftaran Bank Melati telah ditolak.'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('cancelling the confirmation does nothing', (tester) async {
    stubTabs();
    await openScreen(tester);

    await tester.tap(find.text('Setujui').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(api.requests.where((r) => r.method == 'POST'), isEmpty);
  });

  testWidgets('a failed approval shows the error and restores the buttons',
      (tester) async {
    stubTabs();
    api.on('POST', '$_path/1/approve',
        status: 409, json: {'error': 'Sudah diproses'});
    await openScreen(tester);

    await tester.tap(find.text('Setujui').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya, Setujui'));
    await pumpToast(tester);

    expect(find.text('Sudah diproses'), findsOneWidget);
    expect(find.text('Setujui'), findsWidgets);
    await settleToasts(tester);
  });

  testWidgets('shows the proof of a pending bank', (tester) async {
    stubTabs();
    await openScreen(tester);

    await tester.tap(find.text('Lihat Bukti').first);
    await tester.pumpAndSettle();

    expect(find.text('Tidak ada foto kegiatan'), findsOneWidget);
  });

  testWidgets('the Disetujui tab lists approved banks, or an empty note',
      (tester) async {
    stubTabs();
    await openScreen(tester);

    api.on('GET', _path, json: {
      'results': [bankRow('3', nama: 'Bank Aktif', status: 'active')],
    });
    await tester.tap(find.text('Disetujui'));
    await tester.pumpAndSettle();
    expect(find.text('Bank Aktif'), findsOneWidget);
    expect(find.text('Terdaftar: 1 Sep 2026'), findsOneWidget);

    api.on('GET', _path, json: {'results': []});
    await tester.tap(find.text('Ditolak'));
    await tester.pumpAndSettle();
    expect(find.text('Belum Ada Penolakan'), findsOneWidget);

    await tester.tap(find.text('Menunggu'));
    await tester.pumpAndSettle();
    expect(find.text('Tidak Ada Pengajuan'), findsOneWidget);

    await tester.tap(find.text('Disetujui'));
    await tester.pumpAndSettle();
    expect(find.text('Belum Ada yang Disetujui'), findsOneWidget);
  });

  testWidgets('the Ditolak tab lists rejected banks', (tester) async {
    stubTabs();
    await openScreen(tester);

    api.on('GET', _path, json: {
      'results': [
        bankRow('4', nama: 'Bank Ditolak', status: 'rejected', kota: ' '),
        bankRow('5',
            nama: 'Bank Tanpa Lokasi',
            status: 'rejected',
            kota: '',
            alamat: ''),
      ],
    });
    await tester.tap(find.text('Ditolak'));
    await tester.pumpAndSettle();

    expect(find.text('Bank Ditolak'), findsOneWidget);
    expect(find.text('DITOLAK'), findsNWidgets(2));
    expect(find.text('Jl. Melati 1'), findsOneWidget);
  });

  testWidgets('re-tapping the current tab does not refetch', (tester) async {
    stubTabs();
    await openScreen(tester);
    final before = api.requests.length;

    await tester.tap(find.text('Menunggu'));
    await tester.pumpAndSettle();

    expect(api.requests.length, before);
  });

  testWidgets('a failed load shows the message, and pulling retries',
      (tester) async {
    api.on('GET', _path, status: 500, json: {});
    await openScreen(tester);
    expect(find.text('Gagal Memuat Data'), findsOneWidget);

    stubTabs();
    await tester.fling(
        find.text('Gagal Memuat Data'), const Offset(0, 500), 1000);
    await tester.pumpAndSettle();

    expect(find.text('Bank Melati'), findsOneWidget);
  });

  testWidgets('logging out is requested from the header', (tester) async {
    stubTabs();
    await openScreen(tester);

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pump();

    verify(() => auth.add(any(that: isA<LogoutRequested>()))).called(1);
  });

  testWidgets('leaves for the login page once signed out', (tester) async {
    stubTabs();
    final bloc = MockAuthBloc();
    final states =
        Stream<AuthenticationStates>.fromIterable([Unauthenticated()]);
    whenListen(bloc, states,
        initialState: Authenticated(authEntity: testAuth()));
    auth = bloc;

    await openScreen(tester);

    expect(find.text('route:/login'), findsOneWidget);
  });
}
