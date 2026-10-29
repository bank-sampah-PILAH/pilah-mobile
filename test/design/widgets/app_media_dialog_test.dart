import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/widgets/app_media_dialog.dart';

void main() {
  Future<void> open(WidgetTester tester, {String? closeLabel}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showAppMediaDialog(
              context,
              child: const Text('foto'),
              closeLabel: closeLabel ?? 'Tutup',
            ),
            child: const Text('buka'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the media it is given', (tester) async {
    await open(tester);

    expect(find.byType(AppMediaDialog), findsOneWidget);
    expect(find.text('foto'), findsOneWidget);
  });

  testWidgets('is a white dialog rounded like the other dialogs',
      (tester) async {
    await open(tester);

    final dialog = tester.widget<Dialog>(find.byType(Dialog));
    expect(dialog.backgroundColor, Colors.white);
    expect(
      dialog.shape,
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    );
  });

  testWidgets('the cross in the corner closes it', (tester) async {
    await open(tester);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(AppMediaDialog), findsNothing);
  });

  testWidgets('the button at the foot closes it, with the label it is given',
      (tester) async {
    await open(tester, closeLabel: 'Selesai');

    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();

    expect(find.byType(AppMediaDialog), findsNothing);
  });

  testWidgets('dims the screen behind it to black', (tester) async {
    await open(tester);

    final barrier = tester.widget<ModalBarrier>(
      find.byType(ModalBarrier).last,
    );
    expect(barrier.color, AppColors.black.withValues(alpha: 0.87));
  });
}
