import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/theme/app_theme.dart';

import 'package:pilah_mobile/features/nasabah/presentation/widgets/tambah_nasabah_bottom_sheet.dart';
import '../../../../support/nasabah_support.dart';

void main() {
  // Tests measure text with a placeholder font unless the real one is loaded,
  // which would make any hint look too wide.
  setUpAll(() async {
    final poppins = FontLoader('Poppins')
      ..addFont(rootBundle.load('assets/fonts/PoppinsRegular.ttf'));
    await poppins.load();
  });

  testWidgets(
      'the ID Nasabah hint is not cut off on a phone-width sheet (390 px)',
      (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(withNasabahProvider(
      TestNasabahNotifier(),
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: TambahNasabahBottomSheet()),
      ),
    ));

    // The ID field shares a row with Jenis Kelamin, so it is only half wide.
    final hint = find.descendant(
      of: find.byType(TextFormField).at(1),
      matching: find.byType(Text),
    );
    expect(tester.renderObject<RenderParagraph>(hint).didExceedMaxLines, false);
  });
}
