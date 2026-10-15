import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/theme/app_theme.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/widgets/pencairan_ui.dart';

void main() {
  testWidgets('a pencairan filter chip announces its selection and count',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: PencairanChip(
          label: 'Semua',
          selected: true,
          count: 4,
          onTap: () {},
        ),
      ),
    ));

    expect(
      tester.getSemantics(find.byType(PencairanChip)),
      isSemantics(
        label: 'Semua, 4',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
      ),
    );
    handle.dispose();
  });
}
