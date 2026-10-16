import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/widgets/app_back_header.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows a back button and the title beside it', (tester) async {
    await tester.pumpWidget(host(
      AppBackHeader(title: 'Catat Pencairan', onBack: () {}),
    ));

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.text('Catat Pencairan'), findsOneWidget);
    expect(
      tester.getCenter(find.byIcon(Icons.arrow_back)).dx,
      lessThan(tester.getCenter(find.text('Catat Pencairan')).dx),
    );
  });

  testWidgets('the title is 20 bold', (tester) async {
    await tester.pumpWidget(host(
      AppBackHeader(title: 'Catat Pencairan', onBack: () {}),
    ));

    final style = tester
        .renderObject<RenderParagraph>(find.text('Catat Pencairan'))
        .text
        .style;
    expect(style?.fontSize, 20);
    expect(style?.fontWeight, FontWeight.bold);
  });

  testWidgets('reports a tap on the back button', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(
      AppBackHeader(title: 'Catat Pencairan', onBack: () => taps++),
    ));

    await tester.tap(find.byIcon(Icons.arrow_back));

    expect(taps, 1);
  });

  testWidgets('is announced as a button named Kembali', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(
      AppBackHeader(title: 'Catat Pencairan', onBack: () {}),
    ));

    expect(
      tester.getSemantics(find.bySemanticsLabel('Kembali')),
      matchesSemantics(
        label: 'Kembali',
        isButton: true,
        hasTapAction: true,
        isEnabled: true,
        hasEnabledState: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });
}
