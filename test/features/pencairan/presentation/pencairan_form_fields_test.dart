import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/widgets/app_chip.dart';
import 'package:pilah_mobile/design/widgets/app_field_label.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/presentation/widgets/pencairan_form_fields.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  group('MetodePencairanSelector', () {
    testWidgets('captions the choice and offers every metode as a chip',
        (tester) async {
      await tester.pumpWidget(host(MetodePencairanSelector(
        selected: MetodePencairan.tunai,
        onChanged: (_) {},
      )));

      expect(find.widgetWithText(AppFieldLabel, 'METODE'), findsOneWidget);
      for (final metode in MetodePencairan.values) {
        expect(find.byKey(Key('metode-chip-${metode.name}')), findsOneWidget);
      }
    });

    testWidgets('marks only the selected metode', (tester) async {
      await tester.pumpWidget(host(MetodePencairanSelector(
        selected: MetodePencairan.transfer,
        onChanged: (_) {},
      )));

      AppChip chip(MetodePencairan m) =>
          tester.widget(find.byKey(Key('metode-chip-${m.name}')));
      expect(chip(MetodePencairan.transfer).selected, isTrue);
      expect(chip(MetodePencairan.tunai).selected, isFalse);
    });

    testWidgets('reports the metode that was tapped', (tester) async {
      MetodePencairan? picked;
      await tester.pumpWidget(host(MetodePencairanSelector(
        selected: MetodePencairan.tunai,
        onChanged: (m) => picked = m,
      )));

      await tester.tap(find.byKey(const Key('metode-chip-transfer')));

      expect(picked, MetodePencairan.transfer);
    });
  });

  group('TanggalPencairanField', () {
    testWidgets('captions the field and shows the date in Indonesian',
        (tester) async {
      await tester.pumpWidget(host(TanggalPencairanField(
        tanggal: DateTime(2026, 10, 14),
        onTap: () {},
      )));

      expect(find.widgetWithText(AppFieldLabel, 'TANGGAL'), findsOneWidget);
      expect(find.text('14 Oktober 2026'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month), findsOneWidget);
    });

    testWidgets('reports a tap on the field', (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(TanggalPencairanField(
        tanggal: DateTime(2026, 10, 14),
        onTap: () => taps++,
      )));

      await tester.tap(find.byKey(const Key('tanggal-field')));

      expect(taps, 1);
    });

    testWidgets('shows an error under the field', (tester) async {
      await tester.pumpWidget(host(TanggalPencairanField(
        tanggal: DateTime(2026, 10, 14),
        onTap: () {},
        errorText: 'Tanggal tidak valid',
      )));

      expect(find.text('Tanggal tidak valid'), findsOneWidget);
    });
  });
}
