import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/widgets/app_panel_header.dart';

Future<void> _pump(WidgetTester tester, AppPanelHeader header) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: header)));

void main() {
  testWidgets('shows a title and a subtitle', (tester) async {
    await _pump(
        tester, const AppPanelHeader(title: 'Plastik PET', subtitle: 'Detail'));

    expect(find.text('Plastik PET'), findsOneWidget);
    expect(find.text('Detail'), findsOneWidget);
    expect(find.byTooltip('Kembali'), findsNothing);
    expect(find.byTooltip('Tutup'), findsNothing);
  });

  testWidgets('back and close call their own callbacks', (tester) async {
    var back = 0;
    var close = 0;
    await _pump(
      tester,
      AppPanelHeader(
        title: 'Riwayat',
        onBack: () => back++,
        onClose: () => close++,
      ),
    );

    await tester.tap(find.byTooltip('Kembali'));
    await tester.tap(find.byTooltip('Tutup'));

    expect((back, close), (1, 1));
  });

  testWidgets('back sits left of the title and close right of it',
      (tester) async {
    await _pump(
      tester,
      AppPanelHeader(title: 'Riwayat', onBack: () {}, onClose: () {}),
    );

    final back = tester.getRect(find.byTooltip('Kembali'));
    final title = tester.getRect(find.text('Riwayat'));
    final close = tester.getRect(find.byTooltip('Tutup'));
    expect(back.right, lessThanOrEqualTo(title.left));
    expect(close.left, greaterThanOrEqualTo(title.right));
    expect(back.size, const Size(40, 40));
    expect(close.size, back.size, reason: 'the two buttons look the same');
  });

  testWidgets('the height does not depend on the subtitle', (tester) async {
    await _pump(tester, const AppPanelHeader(title: 'A', subtitle: 'B'));
    final with_ = tester.getSize(find.byType(AppPanelHeader)).height;
    await _pump(tester, const AppPanelHeader(title: 'A'));

    expect(tester.getSize(find.byType(AppPanelHeader)).height, with_);
    expect(with_, AppPanelHeader.height);
  });

  testWidgets('a long title is cut with an ellipsis, not overflowed',
      (tester) async {
    await _pump(
      tester,
      AppPanelHeader(
        title: 'Judul yang sangat panjang sekali ' * 5,
        onBack: () {},
        onClose: () {},
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
