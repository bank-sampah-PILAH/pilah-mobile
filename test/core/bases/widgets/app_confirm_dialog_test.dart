import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/bases/widgets/app_confirm_dialog.dart';
import 'package:pilah_mobile/design/theme/app_theme.dart';

void main() {
  bool? answer;

  Future<void> open(WidgetTester tester) async {
    answer = null;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              answer = await showAppConfirmDialog(
                context,
                title: 'Keluar dari akun?',
                message: 'Anda perlu masuk kembali untuk mengakses akun ini.',
                confirmLabel: 'Ya, Keluar',
                destructive: true,
              );
            },
            child: const Text('buka'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the question with a cancel and a confirm button',
      (tester) async {
    await open(tester);

    expect(find.text('Keluar dari akun?'), findsOneWidget);
    expect(find.text('Anda perlu masuk kembali untuk mengakses akun ini.'),
        findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
    expect(find.text('Ya, Keluar'), findsOneWidget);
  });

  testWidgets('confirming answers true', (tester) async {
    await open(tester);

    await tester.tap(find.text('Ya, Keluar'));
    await tester.pumpAndSettle();

    expect(answer, isTrue);
    expect(find.text('Keluar dari akun?'), findsNothing);
  });

  testWidgets('cancelling answers false', (tester) async {
    await open(tester);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(answer, isFalse);
  });

  testWidgets('dismissing by tapping outside answers false', (tester) async {
    await open(tester);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(answer, isFalse);
  });
}
