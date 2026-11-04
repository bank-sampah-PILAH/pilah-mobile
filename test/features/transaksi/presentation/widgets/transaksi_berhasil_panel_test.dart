import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/theme/app_theme.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/transaksi_berhasil_panel.dart';

void main() {
  var whatsApp = 0;
  var selesai = 0;
  Completer<void>? whatsAppHeld;

  Future<void> open(WidgetTester tester) async {
    whatsApp = 0;
    selesai = 0;
    whatsAppHeld = null;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: TransaksiBerhasilPanel(
            customerName: 'Budi Santoso',
            totalSetoran: 5000,
            newBalance: 30000,
            itemCount: 1,
            onKirimWa: () async {
              whatsApp++;
              await whatsAppHeld?.future;
            },
            onSelesai: () => selesai++,
          ),
        ),
      ),
    ));
  }

  AppButton button(WidgetTester tester, String label) =>
      tester.widget<AppButton>(find.widgetWithText(AppButton, label));

  testWidgets('offers sending the WhatsApp message or simply finishing',
      (tester) async {
    await open(tester);

    expect(find.text('Kirim WhatsApp'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
  });

  testWidgets('finishing does not send the WhatsApp message', (tester) async {
    await open(tester);

    await tester.tap(find.text('Selesai'));
    await tester.pump();

    expect(selesai, 1);
    expect(whatsApp, 0);
  });

  testWidgets('sending the WhatsApp message does not just finish',
      (tester) async {
    await open(tester);

    await tester.tap(find.text('Kirim WhatsApp'));
    await tester.pump();

    expect(whatsApp, 1);
    expect(selesai, 0);
  });

  testWidgets('while the message is being prepared neither choice can be taken',
      (tester) async {
    await open(tester);
    whatsAppHeld = Completer<void>();

    await tester.tap(find.text('Kirim WhatsApp'));
    await tester.pump();

    expect(button(tester, 'Selesai').onPressed, isNull);
    await tester.tap(find.text('Selesai'), warnIfMissed: false);
    expect(selesai, 0);
    // The loading button shows a spinner in place of its label, so it is
    // found by type: the first AppButton is the primary one.
    final primary = find.byType(AppButton).first;
    expect(tester.widget<AppButton>(primary).isLoading, isTrue);
    await tester.tap(primary, warnIfMissed: false);
    expect(whatsApp, 1, reason: 'a second tap must not start a second message');

    whatsAppHeld!.complete();
    await tester.pumpAndSettle();
    expect(button(tester, 'Selesai').onPressed, isNotNull);
  });

  testWidgets(
      'once finishing is chosen the panel is leaving: no second finish and no message',
      (tester) async {
    await open(tester);

    await tester.tap(find.text('Selesai'));
    await tester.pump();

    // The sheet is still hit-testable while its exit animation plays.
    expect(button(tester, 'Selesai').onPressed, isNull);
    await tester.tap(find.text('Selesai'), warnIfMissed: false);
    final primary = find.byType(AppButton).first;
    expect(tester.widget<AppButton>(primary).isLoading, isTrue);
    await tester.tap(primary, warnIfMissed: false);
    await tester.pump();

    expect(selesai, 1, reason: 'a second tap must not leave twice');
    expect(whatsApp, 0, reason: 'the panel already left without a message');
  });

  testWidgets('finishing is the quieter choice, sending is the main one',
      (tester) async {
    await open(tester);

    expect(button(tester, 'Kirim WhatsApp').variant, AppButtonVariant.primary);
    expect(button(tester, 'Selesai').variant, AppButtonVariant.outlined);
  });
}
