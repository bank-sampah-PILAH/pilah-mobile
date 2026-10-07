import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/bases/widgets/activity_item.dart';

void main() {
  Widget item({String? badge}) => MaterialApp(
        home: Scaffold(
          body: ActivityItem(
            avatarText: 'SA',
            avatarColor: Colors.green.shade100,
            avatarTextColor: Colors.green,
            title: 'Siti Aminah',
            subtitleLines: const ['Transfer'],
            amount: '-Rp 15.000',
            trailingCaptions: const ['10:00'],
            badge: badge,
          ),
        ),
      );

  testWidgets('shows who, how much and when', (tester) async {
    await tester.pumpWidget(item());

    expect(find.text('Siti Aminah'), findsOneWidget);
    expect(find.text('Transfer'), findsOneWidget);
    expect(find.text('-Rp 15.000'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);
  });

  testWidgets('puts an optional badge under the captions', (tester) async {
    await tester.pumpWidget(item(badge: 'Diperbarui'));
    expect(find.text('Diperbarui'), findsOneWidget);

    await tester.pumpWidget(item());
    expect(find.text('Diperbarui'), findsNothing);
  });
}
