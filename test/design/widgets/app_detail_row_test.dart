import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/widgets/app_detail_row.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        home: Scaffold(body: SizedBox(width: 300, child: child)),
      );

  testWidgets('shows the label on the left and the value on the right',
      (tester) async {
    await tester.pumpWidget(host(
      const AppDetailRow(label: 'Metode', value: 'Tunai'),
    ));

    expect(find.text('Metode'), findsOneWidget);
    expect(find.text('Tunai'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Metode')).dx,
      lessThan(tester.getTopLeft(find.text('Tunai')).dx),
    );
    expect(tester.getTopRight(find.text('Tunai')).dx, 300);
  });

  testWidgets('the label is muted and 13, the value is 13 medium',
      (tester) async {
    await tester.pumpWidget(host(
      const AppDetailRow(label: 'Metode', value: 'Tunai'),
    ));

    TextStyle? style(String text) =>
        tester.renderObject<RenderParagraph>(find.text(text)).text.style;
    expect(style('Metode')?.fontSize, 13);
    expect(style('Tunai')?.fontSize, 13);
    expect(style('Tunai')?.fontWeight, FontWeight.w500);
    expect(style('Metode')?.color, isNot(style('Tunai')?.color));
  });

  testWidgets('a long value wraps instead of overflowing', (tester) async {
    await tester.pumpWidget(host(
      const AppDetailRow(
        label: 'Catatan',
        value: 'Diambil langsung oleh nasabah pada pagi hari di balai warga',
      ),
    ));

    expect(tester.takeException(), isNull);
  });
}
