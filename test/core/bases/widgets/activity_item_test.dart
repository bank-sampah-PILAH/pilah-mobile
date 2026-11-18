import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/bases/widgets/activity_item.dart';

void main() {
  Widget item({String? badge, List<String> captions = const ['10:00']}) =>
      MaterialApp(
        home: Scaffold(
          body: ActivityItem(
            avatarText: 'SA',
            avatarColor: Colors.green.shade100,
            avatarTextColor: Colors.green,
            title: 'Siti Aminah',
            subtitleLines: const ['Transfer'],
            amount: '-Rp 15.000',
            trailingCaptions: captions,
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

  testWidgets('date and time share one line', (tester) async {
    await tester.pumpWidget(item(captions: const ['14/10/2026', '23:00']));

    expect(tester.getTopLeft(find.text('23:00')).dy,
        tester.getTopLeft(find.text('14/10/2026')).dy);
    expect(tester.getTopLeft(find.text('23:00')).dx,
        greaterThan(tester.getTopRight(find.text('14/10/2026')).dx));
  });

  testWidgets('the text is vertically centred on the avatar', (tester) async {
    await tester.pumpWidget(item(captions: const ['14/10/2026', '23:00']));

    final avatar = tester.getCenter(find.text('SA')).dy;
    expect(tester.getCenter(find.text('Siti Aminah')).dy, closeTo(avatar, 12));
    final block = tester
        .getRect(find.text('Siti Aminah'))
        .expandToInclude(tester.getRect(find.text('Transfer')));
    expect(block.center.dy, closeTo(avatar, 1));
  });
}
