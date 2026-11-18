import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/item_setoran_card.dart';
import '../../../../support/harga_support.dart';
import '../../../../support/stub_api.dart';

void main() {
  late TestHargaNotifier hargaNotifier;

  setUp(() {
    hargaNotifier = TestHargaNotifier(buildHargaNotifier(StubApi()));
  });

  /// Pumps a card seeded with [berat] and captures every value its `onChanged`
  /// reports, so a test can read back the parsed weight.
  Future<List<Map<String, dynamic>>> pumpCard(
    WidgetTester tester, {
    num berat = 1.0,
  }) async {
    final changes = <Map<String, dynamic>>[];
    await tester.pumpWidget(
      withHargaProvider(
        hargaNotifier,
        MaterialApp(
          home: Scaffold(
            body: ItemSetoranCard(
              index: 0,
              itemData: {
                'jenis': null,
                'jenis_sampah_id': null,
                'harga': 0,
                'berat': berat
              },
              onChanged: changes.add,
              onDelete: () {},
            ),
          ),
        ),
      ),
    );
    return changes;
  }

  /// The berat input is the second (editable) TextFormField; the harga one above
  /// it is read-only.
  Finder beratField() => find.byType(TextFormField).last;

  group('ItemSetoranCard berat input', () {
    testWidgets('seeds the field with a comma-formatted weight',
        (tester) async {
      await pumpCard(tester, berat: 2.5);

      // The berat field shows the same comma format used across the app.
      expect(find.text('2,5'), findsOneWidget);
      expect(find.text('2.5'), findsNothing);
    });

    testWidgets(
        'accepts a comma decimal and normalises it to a dot for parsing',
        (tester) async {
      final changes = await pumpCard(tester);

      await tester.enterText(beratField(), '2,3');

      expect(changes.last['berat'], 2.3);
    });

    testWidgets('accepts a dot decimal unchanged', (tester) async {
      final changes = await pumpCard(tester);

      await tester.enterText(beratField(), '2.3');

      expect(changes.last['berat'], 2.3);
    });

    testWidgets('parses a multi-digit comma weight (10,75 -> 10.75)',
        (tester) async {
      final changes = await pumpCard(tester);

      await tester.enterText(beratField(), '10,75');

      expect(changes.last['berat'], 10.75);
    });

    testWidgets('blocks a second decimal separator', (tester) async {
      await pumpCard(tester);

      await tester.enterText(beratField(), '2,,3');
      await tester.pump();

      // The anchored formatter keeps only the first separator.
      final editable =
          tester.widgetList<EditableText>(find.byType(EditableText)).last;
      expect(editable.controller.text, '2,');
      expect(editable.controller.text.split(RegExp(r'[.,]')).length - 1, 1);
    });

    testWidgets('lets a dot decimal be typed character by character',
        (tester) async {
      final changes = await pumpCard(tester);

      // enterText replaces wholesale; showKeyboard + per-character entry proves
      // the formatter does not reject the separator mid-typing.
      await tester.enterText(beratField(), '2');
      await tester.enterText(beratField(), '2.');
      await tester.enterText(beratField(), '2.5');

      expect(changes.last['berat'], 2.5);
    });
  });
}
