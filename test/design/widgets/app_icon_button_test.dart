import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/design/widgets/app_icon_button.dart';

void main() {
  testWidgets('is a button-high square with a tooltip that runs onPressed',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: AppIconButton(
            icon: Icons.download_rounded,
            tooltip: 'Ekspor XLSX',
            onPressed: () => taps++,
          ),
        ),
      ),
    ));

    expect(tester.getSize(find.byType(AppIconButton)),
        const Size.square(AppButton.height));
    expect(find.byTooltip('Ekspor XLSX'), findsOneWidget);
    expect(find.bySemanticsLabel('Ekspor XLSX'), findsOneWidget);

    await tester.tap(find.byType(AppIconButton));
    expect(taps, 1);
  });
}
