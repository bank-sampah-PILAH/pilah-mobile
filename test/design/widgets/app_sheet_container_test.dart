import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/widgets/app_sheet_container.dart';

void main() {
  Widget host(Widget sheet, {EdgeInsets viewInsets = EdgeInsets.zero}) =>
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(viewInsets: viewInsets),
          child: Scaffold(
            body: Align(alignment: Alignment.bottomCenter, child: sheet),
          ),
        ),
      );

  BoxDecoration decoration(WidgetTester tester) => tester
      .widget<Container>(find.byKey(AppSheetContainer.surfaceKey))
      .decoration! as BoxDecoration;

  testWidgets('is a white surface with rounded 24 top corners', (tester) async {
    await tester.pumpWidget(host(
      const AppSheetContainer(child: Text('isi')),
    ));

    expect(decoration(tester).color, Colors.white);
    expect(
      decoration(tester).borderRadius,
      const BorderRadius.vertical(top: Radius.circular(24)),
    );
  });

  testWidgets('can take another colour', (tester) async {
    await tester.pumpWidget(host(
      const AppSheetContainer(color: Color(0xFFF5F5F5), child: Text('isi')),
    ));

    expect(decoration(tester).color, const Color(0xFFF5F5F5));
  });

  testWidgets('pads its content 24 on the sides and 12 above by default',
      (tester) async {
    await tester.pumpWidget(host(
      const AppSheetContainer(child: Text('isi', key: Key('isi'))),
    ));

    final sheet = tester.getRect(find.byKey(AppSheetContainer.surfaceKey));
    final content = tester.getRect(find.byKey(const Key('isi')));
    expect(content.left - sheet.left, 24);
    expect(content.top - sheet.top, 12);
  });

  testWidgets('takes its own padding', (tester) async {
    await tester.pumpWidget(host(
      const AppSheetContainer(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Text('isi', key: Key('isi')),
      ),
    ));

    final sheet = tester.getRect(find.byKey(AppSheetContainer.surfaceKey));
    final content = tester.getRect(find.byKey(const Key('isi')));
    expect(content.left - sheet.left, 16);
    expect(content.top - sheet.top, 16);
  });

  testWidgets('rises above the keyboard', (tester) async {
    await tester.pumpWidget(host(
      const AppSheetContainer(child: Text('isi')),
      viewInsets: const EdgeInsets.only(bottom: 300),
    ));

    final sheet = tester.getRect(find.byKey(AppSheetContainer.surfaceKey));
    expect(sheet.bottom, 600 - 300);
  });

  testWidgets('scrolls a content taller than the screen', (tester) async {
    await tester.pumpWidget(host(
      const AppSheetContainer(child: SizedBox(height: 2000, width: 100)),
    ));

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
