import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/widgets/app_field_label.dart';

void main() {
  testWidgets('shows the caption of a field', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppFieldLabel('NAMA LENGKAP'))),
    );

    expect(find.text('NAMA LENGKAP'), findsOneWidget);
  });

  testWidgets('is a small bold caption in the muted grey, loosely spaced',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppFieldLabel('NAMA LENGKAP'))),
    );

    final style = tester
        .renderObject<RenderParagraph>(find.text('NAMA LENGKAP'))
        .text
        .style;
    expect(style?.fontSize, 10);
    expect(style?.fontWeight, FontWeight.bold);
    expect(style?.color, AppColors.grey100);
    expect(style?.letterSpacing, 0.5);
  });

  testWidgets('is read by a screen reader as its text', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppFieldLabel('EMAIL'))),
    );

    expect(
      tester.getSemantics(find.text('EMAIL')),
      matchesSemantics(label: 'EMAIL'),
    );
    handle.dispose();
  });

  testWidgets('marks a required field with an asterisk', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppFieldLabel('ALASAN PERUBAHAN', isRequired: true),
        ),
      ),
    );

    expect(find.text('ALASAN PERUBAHAN'), findsOneWidget);
    expect(find.text('*'), findsOneWidget);
  });

  testWidgets('leaves a field unmarked unless it is required', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppFieldLabel('CATATAN'))),
    );

    expect(find.text('CATATAN'), findsOneWidget);
    expect(find.text('*'), findsNothing);
  });

  testWidgets('draws the required marker in the danger red at caption size',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppFieldLabel('ALASAN PERUBAHAN', isRequired: true),
        ),
      ),
    );

    final style =
        tester.renderObject<RenderParagraph>(find.text('*')).text.style;
    expect(style?.color, AppColors.danger);
    expect(style?.fontSize, 10);
    expect(style?.fontWeight, FontWeight.bold);
  });

  testWidgets('is read by a screen reader as wajib diisi when required',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppFieldLabel('ALASAN PERUBAHAN', isRequired: true),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('ALASAN PERUBAHAN, wajib diisi'),
      findsOneWidget,
    );
    handle.dispose();
  });
}
