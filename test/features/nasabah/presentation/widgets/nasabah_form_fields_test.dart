import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_form_fields.dart';

Future<GlobalKey<FormState>> _pump(WidgetTester tester, Widget child) async {
  final key = GlobalKey<FormState>();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: Form(key: key, child: child)),
      ),
    ),
  );
  return key;
}

void main() {
  group('NasabahFormSheet', () {
    testWidgets('lays out title, subtitle, fields and the button',
        (tester) async {
      final key = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NasabahFormSheet(
              title: 'Tambah Nasabah',
              formKey: key,
              fields: const [Text('field-1'), Text('field-2')],
              button: const Text('tombol'),
            ),
          ),
        ),
      );

      expect(find.text('Tambah Nasabah'), findsOneWidget);
      expect(find.textContaining('nomor WhatsApp aktif'), findsOneWidget);
      expect(find.text('field-1'), findsOneWidget);
      expect(find.text('field-2'), findsOneWidget);
      expect(find.text('tombol'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('field-1')).dy,
        lessThan(tester.getTopLeft(find.text('tombol')).dy),
      );
    });

    testWidgets('shows a notice under the subtitle only when given',
        (tester) async {
      final key = GlobalKey<FormState>();
      Widget sheet({Widget? notice}) => MaterialApp(
            home: Scaffold(
              body: NasabahFormSheet(
                title: 'Edit Nasabah',
                formKey: key,
                notice: notice,
                fields: const [Text('field')],
                button: const Text('tombol'),
              ),
            ),
          );

      await tester.pumpWidget(sheet());
      expect(find.text('catatan'), findsNothing);

      await tester.pumpWidget(sheet(notice: const Text('catatan')));
      expect(find.text('catatan'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('catatan')).dy,
        greaterThan(
            tester.getTopLeft(find.textContaining('nomor WhatsApp')).dy),
      );
    });

    testWidgets('validates its fields through the form key', (tester) async {
      final key = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NasabahFormSheet(
              title: 'T',
              formKey: key,
              fields: [NasabahNameField(controller: TextEditingController())],
              button: const SizedBox(),
            ),
          ),
        ),
      );

      expect(key.currentState!.validate(), isFalse);
    });
  });

  group('NasabahFormField', () {
    testWidgets('puts the caption above the field', (tester) async {
      await _pump(
        tester,
        const NasabahFormField(
          label: 'EMAIL',
          child: SizedBox(key: Key('field'), height: 10),
        ),
      );

      expect(
        tester.getBottomLeft(find.text('EMAIL')).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.byKey(const Key('field'))).dy),
      );
    });

    testWidgets('leaves space below unless told not to', (tester) async {
      Future<double> height({required bool spaced}) async {
        await _pump(
          tester,
          NasabahFormField(
            label: 'X',
            spaced: spaced,
            child: const SizedBox(height: 10),
          ),
        );
        return tester.getSize(find.byType(NasabahFormField)).height;
      }

      final spaced = await height(spaced: true);
      final tight = await height(spaced: false);

      expect(spaced - tight, 20);
    });
  });

  group('NasabahNameField', () {
    testWidgets('is required', (tester) async {
      final controller = TextEditingController();
      final key = await _pump(tester, NasabahNameField(controller: controller));

      expect(find.text('NAMA LENGKAP'), findsOneWidget);
      expect(key.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Bagian ini wajib diisi.'), findsOneWidget);

      controller.text = 'Budi';
      expect(key.currentState!.validate(), isTrue);
    });
  });

  group('NasabahIdField', () {
    testWidgets('uses the validator, hint and change handler it is given',
        (tester) async {
      var changed = 0;
      final key = await _pump(
        tester,
        NasabahIdField(
          controller: TextEditingController(),
          hintText: 'NAS-0900',
          validator: (_) => 'dipakai',
          onChanged: () => changed++,
        ),
      );

      expect(find.text('ID NASABAH'), findsOneWidget);
      expect(find.text('NAS-0900'), findsOneWidget);
      expect(key.currentState!.validate(), isFalse);

      await tester.enterText(find.byType(TextFormField), 'A');
      expect(changed, 1);
    });

    testWidgets('hasError paints the border red without a message',
        (tester) async {
      await _pump(
        tester,
        NasabahIdField(
          controller: TextEditingController(),
          hintText: 'NAS-0900',
          validator: (_) => null,
          hasError: true,
        ),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      final border = field.decoration!.enabledBorder! as OutlineInputBorder;
      expect(border.borderSide.color, AppColors.danger);
    });
  });

  group('NasabahGenderField', () {
    testWidgets('offers both genders and reports the choice', (tester) async {
      String? picked;
      await _pump(
        tester,
        NasabahGenderField(value: null, onChanged: (v) => picked = v),
      );

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      expect(find.text('Laki-laki'), findsOneWidget);
      await tester.tap(find.text('Perempuan').last);
      await tester.pumpAndSettle();

      expect(picked, 'Perempuan');
    });

    testWidgets('asks for a choice before it is valid', (tester) async {
      final key = await _pump(
        tester,
        NasabahGenderField(value: null, onChanged: (_) {}),
      );

      expect(key.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Pilih jenis kelamin.'), findsOneWidget);
    });

    testWidgets('shows the chosen gender', (tester) async {
      await _pump(
        tester,
        NasabahGenderField(value: 'Laki-laki', onChanged: (_) {}),
      );

      expect(find.text('Laki-laki'), findsOneWidget);
    });
  });

  group('NasabahFieldPair', () {
    testWidgets('puts two fields side by side', (tester) async {
      await _pump(
        tester,
        const NasabahFieldPair(left: Text('kiri'), right: Text('kanan')),
      );

      expect(
        tester.getTopLeft(find.text('kiri')).dx,
        lessThan(tester.getTopLeft(find.text('kanan')).dx),
      );
      expect(tester.getTopLeft(find.text('kiri')).dy,
          tester.getTopLeft(find.text('kanan')).dy);
    });
  });

  group('NasabahEmailField', () {
    testWidgets('is required and must look like an address', (tester) async {
      final controller = TextEditingController();
      final key =
          await _pump(tester, NasabahEmailField(controller: controller));

      expect(key.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Email wajib diisi.'), findsOneWidget);

      controller.text = 'bukan-email';
      expect(key.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Format email tidak valid.'), findsOneWidget);

      controller.text = 'budi@gmail.com';
      expect(key.currentState!.validate(), isTrue);
    });

    testWidgets('tells the sheet when the user types', (tester) async {
      var changed = 0;
      await _pump(
        tester,
        NasabahEmailField(
          controller: TextEditingController(),
          onChanged: () => changed++,
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'budi@gmail.com');

      expect(changed, 1);
    });

    testWidgets('can be switched off', (tester) async {
      await _pump(
        tester,
        NasabahEmailField(
          controller: TextEditingController(text: 'a@b.co'),
          enabled: false,
        ),
      );

      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    });

    testWidgets('shows the server error when the address itself is fine',
        (tester) async {
      final key = await _pump(
        tester,
        NasabahEmailField(
          controller: TextEditingController(text: 'budi@gmail.com'),
          serverError: () => 'Email sudah dipakai',
        ),
      );

      expect(key.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Email sudah dipakai'), findsOneWidget);
    });
  });

  group('NasabahBirthDateField', () {
    testWidgets('formats the selected date for both nasabah sheets',
        (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => pickNasabahBirthDate(context, controller),
                child: const Text('Pilih tanggal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pilih tanggal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      final today = DateTime.now();
      expect(
        controller.text,
        '${today.day.toString().padLeft(2, '0')}/'
        '${today.month.toString().padLeft(2, '0')}/${today.year}',
      );
    });

    testWidgets('keeps the current value when the picker is cancelled',
        (tester) async {
      final controller = TextEditingController(text: '01/01/1990');
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => pickNasabahBirthDate(context, controller),
                child: const Text('Pilih tanggal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pilih tanggal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(controller.text, '01/01/1990');
    });

    testWidgets('is read-only, opens the picker on tap and is required',
        (tester) async {
      var taps = 0;
      final key = await _pump(
        tester,
        NasabahBirthDateField(
          controller: TextEditingController(),
          onTap: () => taps++,
        ),
      );

      expect(find.text('dd/mm/yyyy'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      await tester.tap(find.byType(TextFormField));
      expect(taps, 1);
      expect(key.currentState!.validate(), isFalse);
    });
  });

  group('NasabahPhoneField', () {
    testWidgets('checks the number after the +62', (tester) async {
      final controller = TextEditingController();
      final key = await _pump(
        tester,
        NasabahPhoneField(controller: controller),
      );

      expect(find.text('+62'), findsOneWidget);
      expect(key.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Nomor WhatsApp wajib diisi.'), findsOneWidget);

      controller.text = '12345678';
      expect(key.currentState!.validate(), isFalse);
      await tester.pump();
      expect(
        find.text('Format nomor tidak valid. Mulai dengan angka 8'),
        findsOneWidget,
      );

      controller.text = '81234567890';
      expect(key.currentState!.validate(), isTrue);
    });

    testWidgets('keeps digits only', (tester) async {
      final controller = TextEditingController();
      await _pump(tester, NasabahPhoneField(controller: controller));

      await tester.enterText(find.byType(TextFormField), '8a1-2');

      expect(controller.text, '812');
    });

    testWidgets('shows the server error and clears it as the user types',
        (tester) async {
      var cleared = 0;
      final key = await _pump(
        tester,
        NasabahPhoneField(
          controller: TextEditingController(text: '81234567890'),
          serverError: () => 'Nomor sudah dipakai',
          onChanged: () => cleared++,
        ),
      );

      expect(key.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Nomor sudah dipakai'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '8123456789');
      expect(cleared, 1);
    });
  });

  group('NasabahAddressField', () {
    testWidgets('is a multi-line field checked by the validator it is given',
        (tester) async {
      final key = await _pump(
        tester,
        NasabahAddressField(
          controller: TextEditingController(),
          validator: (_) => 'terlalu pendek',
        ),
      );

      expect(tester.widget<TextField>(find.byType(TextField)).maxLines, 4);
      expect(key.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('terlalu pendek'), findsOneWidget);
    });
  });
}
