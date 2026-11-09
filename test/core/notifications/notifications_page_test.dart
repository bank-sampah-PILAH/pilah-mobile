import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/core/notifications/notifications_page.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../support/stub_api.dart';

void main() {
  testWidgets('shows a notification and marks it read', (tester) async {
    final read = <int>[];
    await tester.pumpWidget(MaterialApp(
        home: NotificationsPage(
      load: () async => [
        {
          'id': 7,
          'title': 'Jadwal baru',
          'body': 'Ada jadwal baru.',
          'read_at': null
        },
        {
          'id': 8,
          'title': 'Jadwal lama',
          'body': 'Ada jadwal lama.',
          'read_at': null
        }
      ],
      markRead: (id) async => read.add(id),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Jadwal baru'), findsOneWidget);
    await tester.tap(find.text('Jadwal baru'));
    await tester.pumpAndSettle();
    expect(read, [7]);
  });

  testWidgets('shows an error and retries loading', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(MaterialApp(
        home: NotificationsPage(
      load: () {
        attempts++;
        return attempts == 1
            ? Future.error(StateError('offline'))
            : Future.value([]);
      },
      markRead: (_) async {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('Notifikasi gagal dimuat.'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Belum ada notifikasi.'), findsOneWidget);
  });

  testWidgets('reports when marking a notification as read fails',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: NotificationsPage(
      load: () async => [
        {
          'id': 7,
          'title': 'Jadwal baru',
          'body': 'Ada jadwal baru.',
          'read_at': null
        }
      ],
      markRead: (_) async => throw StateError('offline'),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jadwal baru'));
    await tester.pump();

    expect(
        find.text('Notifikasi belum dapat ditandai dibaca.'), findsOneWidget);
  });

  testWidgets('opens the notification history endpoint', (tester) async {
    final api = StubApi();
    api.on('GET', '/api/v1/notifications/', json: [
      {
        'id': 7,
        'title': 'Jadwal baru',
        'body': 'Ada jadwal baru.',
        'read_at': null
      }
    ]);
    api.on('POST', '/api/v1/notifications/7/read/', json: {});
    di.registerSingleton<NetworkService>(api.network);
    addTearDown(() => di.unregister<NetworkService>());

    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => TextButton(
                onPressed: () => NotificationsPage.open(context),
                child: const Text('Open')))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Jadwal baru'), findsOneWidget);
    await tester.tap(find.text('Jadwal baru'));
    await tester.pumpAndSettle();
    expect(
        api.requests.map((request) => request.path),
        containsAll([
          '/api/v1/notifications/',
          '/api/v1/notifications/7/read/',
        ]));
  });
}
