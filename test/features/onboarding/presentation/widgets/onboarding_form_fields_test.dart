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

  group('OnboardingBirthDateField', () {
    testWidgets('a nasabah may leave it empty and the label says so',
        (tester) async {
      final key = await _pump(
        tester,
        OnboardingBirthDateField(
          controller: TextEditingController(),
          onTap: () {},
          isOptional: true,
        ),
      );

      expect(find.text('dd/mm/yyyy (opsional)'), findsOneWidget);
      expect(find.textContaining('*', findRichText: true), findsNothing);
      expect(key.currentState!.validate(), isTrue);
    });

    testWidgets('a pengelola still has to give one', (tester) async {
      final key = await _pump(
        tester,
        OnboardingBirthDateField(
          controller: TextEditingController(),
          onTap: () {},
          isOptional: false,
        ),
      );

      expect(find.text('dd/mm/yyyy'), findsOneWidget);
      expect(find.textContaining('*', findRichText: true), findsOneWidget);
      expect(key.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Tanggal lahir wajib diisi'), findsOneWidget);
    });

    testWidgets('a pengelola who gave one passes validation', (tester) async {
      final key = await _pump(
        tester,
        OnboardingBirthDateField(
          controller: TextEditingController(text: '01/01/1990'),
          onTap: () {},
          isOptional: false,
        ),
      );

      expect(key.currentState!.validate(), isTrue);
    });

    testWidgets('the box is read-only, so tapping it opens the picker',
        (tester) async {
      var taps = 0;
      await _pump(
        tester,
        OnboardingBirthDateField(
          controller: TextEditingController(),
          onTap: () => taps++,
          isOptional: true,
        ),
      );

      expect(tester.widget<TextFormField>(find.byType(TextFormField)).enabled,
          isTrue);
      await tester.tap(find.byType(TextFormField));
      expect(taps, 1);
    });

    testWidgets('clears a date that was already picked', (tester) async {
      final controller = TextEditingController(text: '01/01/1990');
      var cleared = 0;
      await _pump(
        tester,
        OnboardingBirthDateField(
          controller: controller,
          onTap: () {},
          isOptional: true,
          onClear: () {
            cleared++;
            controller.clear();
          },
        ),
      );

      expect(find.byTooltip('Hapus tanggal lahir'), findsOneWidget);
      await tester.tap(find.byTooltip('Hapus tanggal lahir'));
      await tester.pump();

      expect(cleared, 1);
      expect(controller.text, isEmpty);
      // The icon goes back to the calendar once there is nothing to clear.
      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
    });

    testWidgets('offers no clear button while there is nothing to clear',
        (tester) async {
      await _pump(
        tester,
        OnboardingBirthDateField(
          controller: TextEditingController(),
          onTap: () {},
          isOptional: true,
          onClear: () {},
        ),
      );

      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
    });

    testWidgets('offers no clear button when the field is not optional',
        (tester) async {
      await _pump(
        tester,
        OnboardingBirthDateField(
          controller: TextEditingController(text: '01/01/1990'),
          onTap: () {},
          isOptional: false,
          onClear: () {},
        ),
      );

      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('offers no clear button when no handler is given',
        (tester) async {
      await _pump(
        tester,
        OnboardingBirthDateField(
          controller: TextEditingController(text: '01/01/1990'),
          onTap: () {},
          isOptional: true,
        ),
      );

      expect(find.byIcon(Icons.close), findsNothing);
    });

    test('errorFor states the rule without pumping a widget', () {
      expect(
        OnboardingBirthDateField.errorFor(null, isOptional: true),
        isNull,
      );
      expect(OnboardingBirthDateField.errorFor('', isOptional: true), isNull);
      expect(
        OnboardingBirthDateField.errorFor(null, isOptional: false),
        'Tanggal lahir wajib diisi',
      );
      expect(
        OnboardingBirthDateField.errorFor('', isOptional: false),
        'Tanggal lahir wajib diisi',
      );
      expect(
        OnboardingBirthDateField.errorFor('01/01/1990', isOptional: false),
        isNull,
      );
    });
  });
}
