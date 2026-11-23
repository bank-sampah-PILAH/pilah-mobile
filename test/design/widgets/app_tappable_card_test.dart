import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/theme/app_theme.dart';
import 'package:pilah_mobile/design/widgets/app_tappable_card.dart';

Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: child)),
    );

void main() {
  testWidgets('a card is a button that reads its own content', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(
      AppTappableCard(
        onTap: () {},
        child: const Column(children: [Text('Nasabah Demo'), Text('Rp 0')]),
      ),
    ));

    final node = tester.getSemantics(find.byType(AppTappableCard));
    expect(node, isSemantics(isButton: true, hasTapAction: true));
    // The text of the card is merged into the button's one semantic node.
    final label = node.getSemanticsData().label;
    expect(label, contains('Nasabah Demo'));
    expect(label, contains('Rp 0'));
    handle.dispose();
  });

  testWidgets('is white and rounded like the cards it replaces',
      (tester) async {
    await tester.pumpWidget(_host(
      AppTappableCard(onTap: () {}, child: const Text('isi')),
    ));

    final box = tester.widget<Container>(find
        .descendant(
          of: find.byType(AppTappableCard),
          matching: find.byType(Container),
        )
        .first);
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.color, Colors.white);
    expect(decoration.borderRadius, BorderRadius.circular(16));
  });

  testWidgets('tapping calls onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(
      AppTappableCard(onTap: () => taps++, child: const Text('Ketuk')),
    ));

    await tester.tap(find.text('Ketuk'));

    expect(taps, 1);
  });
}
