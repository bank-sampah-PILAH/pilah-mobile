import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/bases/widgets/expandable_text.dart';

const _longText =
    'Dokumen kartu tanda penduduk yang saya unggah sebelumnya buram dan tidak '
    'terbaca, saya sudah mengunggah ulang dengan foto yang lebih jelas dan '
    'resolusi tinggi agar pengurus dapat memverifikasi data saya dengan baik.';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 200, child: child),
      ),
    );

void main() {
  testWidgets('hides the toggle when the text fits within the line limit',
      (tester) async {
    await tester.pumpWidget(_wrap(const ExpandableText(text: 'Data lengkap')));
    // Overflow is measured a frame after first layout (see the widget's doc
    // comment on why it can't be done during build under IntrinsicHeight).
    await tester.pump();

    expect(find.text('Lihat Selengkapnya'), findsNothing);
  });

  testWidgets('shows a truncated toggle when the text overflows the limit',
      (tester) async {
    await tester.pumpWidget(_wrap(const ExpandableText(text: _longText)));
    await tester.pump();

    expect(find.text('Lihat Selengkapnya'), findsOneWidget);
    final text = tester.widget<Text>(find.text(_longText));
    expect(text.maxLines, 2);
  });

  testWidgets('expands and collapses when the toggle is tapped',
      (tester) async {
    await tester.pumpWidget(_wrap(const ExpandableText(text: _longText)));
    await tester.pump();

    await tester.tap(find.text('Lihat Selengkapnya'));
    await tester.pump();

    expect(find.text('Sembunyikan'), findsOneWidget);
    var text = tester.widget<Text>(find.text(_longText));
    expect(text.maxLines, isNull);

    await tester.tap(find.text('Sembunyikan'));
    await tester.pump();

    expect(find.text('Lihat Selengkapnya'), findsOneWidget);
    text = tester.widget<Text>(find.text(_longText));
    expect(text.maxLines, 2);
  });

  testWidgets(
      're-measures overflow when the text changes on an already-built widget',
      (tester) async {
    const key = Key('expandable');
    await tester.pumpWidget(
        _wrap(const ExpandableText(key: key, text: 'Data lengkap')));
    await tester.pump();
    expect(find.text('Lihat Selengkapnya'), findsNothing);

    await tester
        .pumpWidget(_wrap(const ExpandableText(key: key, text: _longText)));
    await tester.pump();

    expect(find.text('Lihat Selengkapnya'), findsOneWidget);
  });
}
