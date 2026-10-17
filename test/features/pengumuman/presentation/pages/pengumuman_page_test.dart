import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/pengumuman/data/nasabah_pengumuman_repository.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/cubit/nasabah_pengumuman_cubit.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/pages/pengumuman_page.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

Map<String, dynamic> _row(String id, {bool dibaca = false}) => {
      'id': id,
      'judul': 'Pengumuman $id',
      'isi': 'Isi $id',
      'terbit_pada': '2026-10-15T03:00:00Z',
      'dibaca': dibaca,
      'dibaca_pada': dibaca ? '2026-10-15T05:00:00Z' : null,
    };

void main() {
  late StubApi api;
  late NasabahPengumumanCubit cubit;

  setUp(() {
    api = StubApi();
    cubit = NasabahPengumumanCubit(NasabahPengumumanRepository(api.network));
  });

  tearDown(() => cubit.close());

  Future<void> openPage(WidgetTester tester) async {
    await pumpRouted(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthenticationBloc>.value(
            value: authBlocIn(
                Authenticated(authEntity: testAuth(role: 'nasabah'))),
          ),
          BlocProvider<NasabahPengumumanCubit>.value(value: cubit),
        ],
        child: PengumumanPage(membershipId: 'm-1'),
      ),
      extraRoutes: ['/pengumuman/detail'],
      pushed: true,
      size: const Size(800, 2000),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists announcements with a dot only on unread rows',
      (tester) async {
    api.on('GET', '/api/v1/nasabah/me/pengumuman', json: {
      'count': 2,
      'next': null,
      'results': [_row('1'), _row('2', dibaca: true)],
    });

    await openPage(tester);

    expect(find.byKey(const ValueKey('pengumuman-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('pengumuman-2')), findsOneWidget);
    // Only the unread row carries the dot.
    expect(
        find.byKey(const ValueKey('pengumuman-belum-dibaca')), findsOneWidget);
    // The membership scope reached the backend.
    expect(api.last.query['keanggotaan_id'], 'm-1');
  });

  testWidgets('tapping a row marks it read and opens the detail',
      (tester) async {
    api.on('GET', '/api/v1/nasabah/me/pengumuman', json: {
      'count': 1,
      'next': null,
      'results': [_row('1')],
    });
    api.on('POST', '/api/v1/nasabah/me/pengumuman/1/baca', json: {
      'id': '1',
      'dibaca': true,
      'dibaca_pada': '2026-10-15T06:00:00Z',
    });

    await openPage(tester);
    await tester.tap(find.text('Pengumuman 1'));
    await tester.pumpAndSettle();

    expect(find.text('route:/pengumuman/detail'), findsOneWidget);
    expect(find.byKey(const ValueKey('pengumuman-belum-dibaca')), findsNothing);
  });

  testWidgets('an empty list shows the zero state', (tester) async {
    api.on('GET', '/api/v1/nasabah/me/pengumuman',
        json: {'count': 0, 'next': null, 'results': []});

    await openPage(tester);

    expect(find.text('Belum ada pengumuman'), findsOneWidget);
  });

  testWidgets('a failed load offers to retry', (tester) async {
    api.fail('GET', '/api/v1/nasabah/me/pengumuman');
    await openPage(tester);

    expect(find.text('Belum ada pengumuman'), findsNothing);
    expect(find.text('Coba lagi'), findsOneWidget);

    api.on('GET', '/api/v1/nasabah/me/pengumuman', json: {
      'count': 1,
      'next': null,
      'results': [_row('1')],
    });
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('pengumuman-1')), findsOneWidget);
  });

  testWidgets('a non-nasabah sees the sign-in guard, not the list',
      (tester) async {
    await pumpRouted(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthenticationBloc>.value(
            value: authBlocIn(Unauthenticated()),
          ),
          BlocProvider<NasabahPengumumanCubit>.value(value: cubit),
        ],
        child: const PengumumanPage(),
      ),
      pushed: true,
      size: const Size(800, 2000),
    );
    await tester.pumpAndSettle();

    expect(find.text('Silakan masuk sebagai nasabah.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsNothing);
  });

  testWidgets('nearly filling the viewport does not page early',
      (tester) async {
    api.on('GET', '/api/v1/nasabah/me/pengumuman', json: {
      'count': 1,
      'next': 'http://api.test/api/v1/nasabah/me/pengumuman?page=2',
      'results': [_row('1')],
    });

    await openPage(tester);

    // The single row leaves plenty of scroll after it: no next-page fetch.
    expect(
      api.requests.where((call) => call.query['page'] == '2'),
      isEmpty,
    );
  });

  testWidgets('a list that fills past the viewport pages at its end',
      (tester) async {
    api.on('GET', '/api/v1/nasabah/me/pengumuman', json: {
      'count': 31,
      'next': 'http://api.test/api/v1/nasabah/me/pengumuman?page=2',
      'results': [
        for (var i = 1; i <= 30; i++) _row('$i', dibaca: true),
      ],
    });
    await openPage(tester);
    expect(
      api.requests.where((call) => call.query['page'] == '2'),
      isEmpty,
      reason: 'the rows still leave scroll behind: no next-page fetch yet',
    );

    api.on('GET', '/api/v1/nasabah/me/pengumuman', json: {
      'count': 31,
      'next': null,
      'results': [_row('31')],
    });
    // Drag toward the bottom in small steps until the near-end listener
    // fetches page 2, then let the appended row land.
    for (var i = 0;
        i < 80 && api.requests.every((call) => call.query['page'] != '2');
        i++) {
      await tester.drag(find.byType(ListView).last, const Offset(0, -200));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
    }
    await tester.pumpAndSettle();

    expect(
      api.requests.any((call) => call.query['page'] == '2'),
      isTrue,
    );
    // One more drag reveals the row appended just below the fold.
    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pengumuman-31')), findsOneWidget);
  });

  testWidgets('a pull-to-refresh reloads silently', (tester) async {
    api.on('GET', '/api/v1/nasabah/me/pengumuman', json: {
      'count': 1,
      'next': null,
      'results': [_row('1')],
    });
    await openPage(tester);

    api.on('GET', '/api/v1/nasabah/me/pengumuman', json: {
      'count': 1,
      'next': null,
      'results': [_row('1', dibaca: true)],
    });
    await tester.fling(find.byType(ListView), const Offset(0, 600), 6000);
    await tester.pumpAndSettle();

    final gets = api.requests
        .where((call) =>
            call.method == 'GET' &&
            call.path == '/api/v1/nasabah/me/pengumuman')
        .length;
    expect(gets, 2);
    expect(find.byKey(const ValueKey('pengumuman-belum-dibaca')), findsNothing);
  });
}
