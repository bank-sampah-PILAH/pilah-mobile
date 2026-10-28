import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/pengumuman/data/nasabah_pengumuman_repository.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/providers/nasabah_pengumuman_provider.dart';
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
  late NasabahPengumumanRepository repository;

  setUp(() {
    api = StubApi();
    repository = NasabahPengumumanRepository(api.network);
  });

  Future<void> openPage(WidgetTester tester,
      {Size size = const Size(800, 2000)}) async {
    await pumpRouted(
      tester,
      withAuthenticationProvider(
        authNotifierIn(Authenticated(authEntity: testAuth(role: 'nasabah'))),
        PengumumanPage(membershipId: 'm-1'),
      ),
      extraRoutes: ['/pengumuman/detail'],
      pushed: true,
      size: size,
      wrap: (child) => ProviderScope(
        overrides: [
          nasabahPengumumanProvider.overrideWith(
            () => NasabahPengumumanNotifier(repository),
          ),
        ],
        child: child,
      ),
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
    expect(find.text('Coba Lagi'), findsOneWidget);

    api.on('GET', '/api/v1/nasabah/me/pengumuman', json: {
      'count': 1,
      'next': null,
      'results': [_row('1')],
    });
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('pengumuman-1')), findsOneWidget);
  });

  testWidgets('a non-nasabah sees the sign-in guard, not the list',
      (tester) async {
    await pumpRouted(
      tester,
      withAuthenticationProvider(
        authNotifierIn(Unauthenticated()),
        const PengumumanPage(),
      ),
      pushed: true,
      size: const Size(800, 2000),
    );
    await tester.pumpAndSettle();

    expect(find.text('Silakan masuk sebagai nasabah.'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsNothing);
  });

  testWidgets('reaching the end of the list loads the next page',
      (tester) async {
    api.on('GET', '/api/v1/nasabah/me/pengumuman', json: {
      'count': 9,
      'next': 'http://api.test/api/v1/nasabah/me/pengumuman?page=2',
      'results': [
        for (var i = 1; i <= 8; i++) _row('$i'),
      ],
    });
    await openPage(tester, size: const Size(800, 400));

    api.on('GET', '/api/v1/nasabah/me/pengumuman', json: {
      'count': 9,
      'next': null,
      'results': [_row('9')],
    });
    await tester.fling(find.text('Pengumuman 1'), const Offset(0, -1200), 3000);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('pengumuman-9')), findsOneWidget);
    expect(
      api.requests.where((call) => call.method == 'GET').length,
      greaterThanOrEqualTo(2),
    );
  });

  testWidgets('pulling down refreshes the list in place', (tester) async {
    api.on('GET', '/api/v1/nasabah/me/pengumuman', json: {
      'count': 1,
      'next': null,
      'results': [_row('1')],
    });
    await openPage(tester);

    await tester.drag(find.text('Pengumuman 1'), const Offset(0, 600));
    await tester.pumpAndSettle();

    expect(
      api.requests.where((call) => call.method == 'GET').length,
      greaterThanOrEqualTo(2),
    );
    expect(find.byKey(const ValueKey('pengumuman-1')), findsOneWidget);
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
}
