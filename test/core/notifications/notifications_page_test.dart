import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/notifications/notifications_page.dart';

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
}
