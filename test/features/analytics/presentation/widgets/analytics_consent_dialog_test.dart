import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/theme/app_theme.dart';
import 'package:pilah_mobile/features/analytics/presentation/widgets/analytics_consent_dialog.dart';

void main() {
  bool? answer;
  var answered = false;

  Future<void> open(WidgetTester tester) async {
    answer = null;
    answered = false;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              answer = await showAnalyticsConsentDialog(context);
              answered = true;
            },
            child: const Text('buka'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
  }

  testWidgets('explains what is recorded and offers agree and decline',
      (tester) async {
    await open(tester);

    expect(find.text('Bantu kami memperbaiki PILAH'), findsOneWidget);
    expect(
        find.textContaining('merekam layar dan gerakan Anda'), findsOneWidget);
    expect(find.textContaining('Nama nasabah, saldo, foto, email, dan nomor'),
        findsOneWidget);
    expect(find.textContaining('mengubah pilihan kapan saja di Profil'),
        findsOneWidget);
    expect(find.text('Setuju'), findsOneWidget);
    expect(find.text('Tolak'), findsOneWidget);
  });

  testWidgets('agreeing answers true', (tester) async {
    await open(tester);

    await tester.tap(find.text('Setuju'));
    await tester.pumpAndSettle();

    expect(answer, isTrue);
    expect(find.text('Bantu kami memperbaiki PILAH'), findsNothing);
  });

  testWidgets('declining answers false', (tester) async {
    await open(tester);

    await tester.tap(find.text('Tolak'));
    await tester.pumpAndSettle();

    expect(answer, isFalse);
  });

  testWidgets('tapping outside or going back does not answer for the user',
      (tester) async {
    await open(tester);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Bantu kami memperbaiki PILAH'), findsOneWidget);
    expect(answered, isFalse);
  });
}
