import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/widgets/app_sheet_handle.dart';

void main() {
  Widget host() => const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 300, child: AppSheetHandle()),
        ),
      );

  testWidgets('is a 40 by 4 bar', (tester) async {
    await tester.pumpWidget(host());

    final size = tester.getSize(find.byKey(AppSheetHandle.barKey));
    expect([size.width, size.height], [40, 4]);
  });

  testWidgets('sits in the middle of the sheet', (tester) async {
    await tester.pumpWidget(host());

    expect(tester.getCenter(find.byKey(AppSheetHandle.barKey)).dx, 150);
  });

  testWidgets('is the grey of a divider with rounded ends', (tester) async {
    await tester.pumpWidget(host());

    final box = tester
        .widget<Container>(find.byKey(AppSheetHandle.barKey))
        .decoration! as BoxDecoration;
    expect(box.color, AppColors.border);
    expect(box.borderRadius, BorderRadius.circular(AppRadius.xs));
  });

  testWidgets('is decoration only, so a screen reader skips it',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host());

    expect(find.byType(ExcludeSemantics), findsWidgets);
    handle.dispose();
  });
}
