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
      ),
    );
    handle.dispose();
  });

  testWidgets('shows actions at the right end', (tester) async {
    await tester.pumpWidget(host(
      AppBackHeader(
        title: 'Draft',
        onBack: () {},
        actions: const [Icon(Icons.share, key: Key('aksi'))],
      ),
    ));

    expect(
      tester.getCenter(find.byKey(const Key('aksi'))).dx,
      greaterThan(tester.getCenter(find.text('Draft')).dx),
    );
  });

  testWidgets('a title too long for the line ends in an ellipsis',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 200,
          child: AppBackHeader(
            title: 'Pratinjau PDF laporan pencairan bulan ini',
            onBack: () {},
          ),
        ),
      ),
    ));

    expect(tester.takeException(), isNull);
    final text = tester.renderObject<RenderParagraph>(
      find.text('Pratinjau PDF laporan pencairan bulan ini'),
    );
    expect(text.didExceedMaxLines, isTrue);
  });

  testWidgets('goes back when no onBack is given, asking a PopScope first',
      (tester) async {
    var asked = 0;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => PopScope(
              canPop: false,
              onPopInvokedWithResult: (_, __) => asked++,
              child: const Scaffold(
                body: AppBackHeader(title: 'Editor', backKey: Key('kembali')),
              ),
            ),
          )),
          child: const Text('buka'),
        ),
      ),
    ));
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('kembali')));
    await tester.pumpAndSettle();

    expect(asked, 1);
    expect(find.text('Editor'), findsOneWidget);
  });
}
