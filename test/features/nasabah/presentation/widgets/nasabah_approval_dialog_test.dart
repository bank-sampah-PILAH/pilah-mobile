import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_approval_dialog.dart';

void main() {
  group('NasabahApprovalDialog', () {
    testWidgets('approve returns the typed catatan', (tester) async {
      String? result;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showNasabahApprovalDialog(context,
                      isApproving: true, customerName: 'Budi Santoso');
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Data lengkap');
      await tester.tap(find.text('Setujui'));
      await tester.pumpAndSettle();

      expect(result, 'Data lengkap');
    });

    testWidgets('reject is destructive red and returns the alasan',
        (tester) async {
      String? result;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showNasabahApprovalDialog(context,
                      isApproving: false, customerName: 'Budi Santoso');
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final rejectButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Tolak'),
      );
      expect(rejectButton.style?.backgroundColor?.resolve({}), Colors.red);

      await tester.enterText(find.byType(TextField), 'Alamat tidak valid');
      await tester.tap(find.text('Tolak'));
      await tester.pumpAndSettle();

      expect(result, 'Alamat tidak valid');
    });

    testWidgets('cancel returns null', (tester) async {
      String? result = 'sentinel';
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showNasabahApprovalDialog(context,
                      isApproving: true, customerName: 'Budi Santoso');
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });
}
