import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/register_bank_sampah_screen.dart';

void main() {
  group('RegisterBankSampahScreen re-application mode', () {
    testWidgets('shows the rejection banner and hides the stepper when rejected',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: RegisterBankSampahScreen(isRejectedReapplication: true),
      ));

      // Banner present with the required copy.
      expect(find.text('Pendaftaran Ditolak'), findsOneWidget);
      expect(
        find.textContaining('Pendaftaran sebelumnya ditolak'),
        findsOneWidget,
      );
      // Stepper gone (its labels are unique to the stepper).
      expect(find.text('Data Bank Sampah'), findsNothing);
      // The form itself is unchanged and present (submit button is a plain
      // Text; the field labels are RichText, which find.text can't match).
      expect(find.text('Ajukan Pendaftaran'), findsOneWidget);
    });

    testWidgets('shows the stepper and no banner in normal (first-time) mode',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: RegisterBankSampahScreen(),
      ));

      expect(find.text('Data Bank Sampah'), findsOneWidget); // stepper label
      expect(find.text('Pendaftaran Ditolak'), findsNothing);
      // Same form in both modes.
      expect(find.text('Ajukan Pendaftaran'), findsOneWidget);
    });
  });
}
