import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/onboarding/presentation/widgets/onboarding_form_fields.dart';

Future<GlobalKey<FormState>> _pump(WidgetTester tester, Widget field) async {
  final key = GlobalKey<FormState>();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: Form(key: key, child: field)),
      ),
    ),
  );
  return key;
}

void main() {
  group('OnboardingNameField', () {
    testWidgets('asks for at least three characters', (tester) async {
      final controller = TextEditingController(text: 'Al');
      final key = await _pump(
        tester,
        OnboardingNameField(
          controller: controller,
          label: 'NAMA LENGKAP',
          hintText: 'Contoh: Siti Rahayu',
        ),
      );

      expect(key.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Nama minimal 3 karakter'), findsOneWidget);

      controller.text = 'Ali';
      expect(key.currentState!.validate(), isTrue);
    });

    testWidgets('shows the hint and the label it is given', (tester) async {
      await _pump(
        tester,
        OnboardingNameField(
          controller: TextEditingController(),
          label: 'NAMA BANK SAMPAH',
          hintText: 'Contoh: Bank Sampah Mekar Jaya',
        ),
      );

      expect(find.text('Contoh: Bank Sampah Mekar Jaya'), findsOneWidget);
      expect(
        find.textContaining('NAMA BANK SAMPAH', findRichText: true),
        findsOneWidget,
      );
    });
  });

  group('OnboardingPhoneField', () {
    Future<GlobalKey<FormState>> pump(
      WidgetTester tester,
      TextEditingController controller,
    ) =>
        _pump(
          tester,
          OnboardingPhoneField(
            controller: controller,
            label: 'NOMOR HP / WHATSAPP',
            requiredMessage: 'Nomor HP wajib diisi',
          ),
        );

    testWidgets('is required, with the message it is given', (tester) async {
      final key = await pump(tester, TextEditingController());

      expect(key.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Nomor HP wajib diisi'), findsOneWidget);
    });

    testWidgets('only accepts a number that starts with 8 after the +62',
        (tester) async {
      final controller = TextEditingController(text: '12345678');
      final key = await pump(tester, controller);

      expect(key.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Format nomor tidak valid.'), findsOneWidget);

      controller.text = '81234567890';
      expect(key.currentState!.validate(), isTrue);
    });

    testWidgets('keeps digits only and shows the +62 prefix', (tester) async {
      final controller = TextEditingController();
      await pump(tester, controller);

      await tester.enterText(find.byType(TextFormField), '8a1-2');

      expect(controller.text, '812');
      expect(find.text('+62'), findsOneWidget);
    });
  });

  group('OnboardingAddressField', () {
    testWidgets('is required', (tester) async {
      final controller = TextEditingController(text: '  ');
      final key = await _pump(
        tester,
        OnboardingAddressField(controller: controller),
      );

      expect(key.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Alamat wajib diisi'), findsOneWidget);

      controller.text = 'Jl. Mawar 1';
      expect(key.currentState!.validate(), isTrue);
    });

    testWidgets('is a multi-line field', (tester) async {
      await _pump(
        tester,
        OnboardingAddressField(controller: TextEditingController()),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.maxLines, 5);
      expect(field.minLines, 3);
    });
  });
}
