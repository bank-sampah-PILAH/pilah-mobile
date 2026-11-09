import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/core/notifications/notifications_page.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../support/stub_api.dart';
import '../../support/pump_app.dart';

Map<String, dynamic> notificationPage(
  List<dynamic> results, {
  String? next,
  String? previous,
}) =>
    {
      'count': results.length,
      'next': next,
      'previous': previous,
      'results': results,
    };

void main() {
  testWidgets('does not load the same older page twice concurrently',
      (tester) async {
    final requestedPages = <int>[];
    final pageTwo = Completer<Map<String, dynamic>>();
    await tester.pumpWidget(MaterialApp(
        home: NotificationsPage(
      loadPage: (page) {
        requestedPages.add(page);
        return page == 1
            ? Future.value(notificationPage([
                {
                  'id': 7,
                  'title': 'Jadwal baru',
                  'body': 'Ada jadwal baru.',
                  'read_at': null
                }
              ], next: '?page=2'))
            : pageTwo.future;
      },
      markRead: (_) async {},
      clear: () async => 0,
    )));
    await tester.pumpAndSettle();

    final position = tester.getCenter(find.text('Muat Lagi'));
    final firstTap = await tester.startGesture(position, pointer: 1);
    final secondTap = await tester.startGesture(position, pointer: 2);
    await firstTap.up();
    await secondTap.up();
    await tester.pump();

    expect(requestedPages, [1, 2]);
    expect(
        find.bySemanticsLabel('Memuat notifikasi berikutnya'), findsOneWidget);
    expect(find.text('Muat Lagi'), findsNothing);
    pageTwo.complete(notificationPage([
      {
        'id': 8,
        'title': 'Jadwal lama',
        'body': 'Ada jadwal lama.',
        'read_at': null
      }
    ]));
    await tester.pumpAndSettle();
  });

  testWidgets('loads older notifications on demand and avoids duplicates',
      (tester) async {
    final requestedPages = <int>[];
    await tester.pumpWidget(MaterialApp(
        home: NotificationsPage(
      loadPage: (page) async {
        requestedPages.add(page);
        return page == 1
            ? notificationPage([
                {
                  'id': 7,
                  'title': 'Jadwal baru',
                  'body': 'Ada jadwal baru.',
                  'read_at': null
                }
              ], next: '?page=2')
            : notificationPage([
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
              ], previous: '?page=1');
      },
      markRead: (_) async {},
      clear: () async => 0,
    )));
    await tester.pumpAndSettle();

    expect(requestedPages, [1]);
    expect(find.text('Jadwal baru'), findsOneWidget);
    expect(find.text('Jadwal lama'), findsNothing);

    await tester.tap(find.text('Muat Lagi'));
    await tester.pumpAndSettle();

    expect(requestedPages, [1, 2]);
    expect(find.text('Jadwal baru'), findsOneWidget);
    expect(find.text('Jadwal lama'), findsOneWidget);
    expect(find.text('Muat Lagi'), findsNothing);
  });

  testWidgets('shows a notification and marks it read', (tester) async {
    final read = <int>[];
    await tester.pumpWidget(MaterialApp(
        home: NotificationsPage(
      loadPage: (_) async => notificationPage([
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
      ]),
      markRead: (id) async => read.add(id),
      clear: () async => 0,
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
      loadPage: (_) {
        attempts++;
        return attempts == 1
            ? Future.error(StateError('offline'))
            : Future.value(notificationPage([]));
      },
      markRead: (_) async {},
      clear: () async => 0,
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
      loadPage: (_) async => notificationPage([
        {
          'id': 7,
          'title': 'Jadwal baru',
          'body': 'Ada jadwal baru.',
          'read_at': null
        }
      ]),
      markRead: (_) async => throw StateError('offline'),
      clear: () async => 0,
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jadwal baru'));
    await tester.pump();

    expect(
        find.text('Notifikasi belum dapat ditandai dibaca.'), findsOneWidget);
  });

  testWidgets('confirms clearing, shows loading, and hides after success',
      (tester) async {
    final clearResult = Completer<int>();
    var clearCalls = 0;
    await tester.pumpWidget(MaterialApp(
        home: NotificationsPage(
      loadPage: (_) async => notificationPage([
        {
          'id': 7,
          'title': 'Jadwal baru',
          'body': 'Ada jadwal baru.',
          'read_at': null
        }
      ]),
      markRead: (_) async {},
      clear: () {
        clearCalls++;
        return clearResult.future;
      },
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bersihkan'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('disembunyikan dari kotak masuk'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(clearCalls, 0);
    expect(find.text('Jadwal baru'), findsOneWidget);

    await tester.tap(find.text('Bersihkan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bersihkan').last);
    await tester.pump();
    expect(clearCalls, 1);
    expect(find.text('Membersihkan...'), findsOneWidget);

    clearResult.complete(2);
    await pumpToast(tester);
    expect(find.text('Belum ada notifikasi.'), findsOneWidget);
    expect(find.text('2 notifikasi disembunyikan dari kotak masuk.'),
        findsOneWidget);
  });

  testWidgets('keeps notifications and reports when clearing fails',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: NotificationsPage(
      loadPage: (_) async => notificationPage([
        {
          'id': 7,
          'title': 'Jadwal baru',
          'body': 'Ada jadwal baru.',
          'read_at': null
        }
      ]),
      markRead: (_) async {},
      clear: () async => throw StateError('offline'),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bersihkan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bersihkan').last);
    await pumpToast(tester);

    expect(find.text('Notifikasi belum dapat dibersihkan.'), findsOneWidget);
    expect(find.text('Jadwal baru'), findsOneWidget);
    expect(find.text('Bersihkan'), findsOneWidget);
  });

  testWidgets('opens the notification history endpoint', (tester) async {
    final api = StubApi();
    api.on('GET', '/api/v1/notifications/',
        json: notificationPage([
          {
            'id': 7,
            'title': 'Jadwal baru',
            'body': 'Ada jadwal baru.',
            'read_at': null
          }
        ]));
    api.on('POST', '/api/v1/notifications/7/read/', json: {});
    api.on('POST', '/api/v1/notifications/clear/', json: {'hidden_count': 1});
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
    expect(api.requests.first.query, {'page': '1', 'page_size': '20'});
    await tester.tap(find.text('Jadwal baru'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bersihkan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bersihkan').last);
    await pumpToast(tester);
    expect(
        api.requests.map((request) => request.path),
        containsAll([
          '/api/v1/notifications/',
          '/api/v1/notifications/7/read/',
          '/api/v1/notifications/clear/',
        ]));
    expect(find.text('Belum ada notifikasi.'), findsOneWidget);
  });
}
