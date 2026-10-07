import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_outlined_button.dart';
import 'package:pilah_mobile/design/widgets/atom/app_text_button.dart';
import 'package:pilah_mobile/design/widgets/atom/app_text_field.dart';
import 'package:pilah_mobile/design/widgets/atom/page_indicator.dart';
import 'package:pilah_mobile/design/widgets/atom/primary_button.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/forgot_password_page.dart';

import '../../support/pump_app.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('CustomOutlinedButton', () {
    testWidgets('shows its title and icon, and reports taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(CustomOutlinedButton(
        title: 'Tambah',
        icon: Icons.add,
        borderColor: Colors.green,
        textColor: Colors.green,
        backgroundColor: Colors.yellow,
        onPressed: () => taps++,
      )));

      expect(find.text('Tambah'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      await tester.tap(find.text('Tambah'));
      expect(taps, 1);
    });

    testWidgets('a disabled button is greyed out and does nothing',
        (tester) async {
      await tester.pumpWidget(_host(CustomOutlinedButton(
        title: 'Tambah',
        icon: Icons.add,
        onPressed: null,
      )));

      final text = tester.widget<Text>(find.text('Tambah'));
      expect(text.style?.color, Colors.grey[500]);
      expect(tester.widget<OutlinedButton>(find.byType(OutlinedButton)).enabled,
          isFalse);
    });

    testWidgets('works without an icon', (tester) async {
      await tester.pumpWidget(
          _host(CustomOutlinedButton(title: 'Saja', onPressed: () {})));

      expect(find.byType(Icon), findsNothing);
    });
  });

  group('PrimaryButton', () {
    testWidgets('shows its label and reports taps', (tester) async {
      var taps = 0;
      await tester
          .pumpWidget(_host(PrimaryButton(text: 'Kirim', onTap: () => taps++)));

      await tester.tap(find.text('Kirim'));

      expect(taps, 1);
    });

    testWidgets('shows a spinner instead of the label while loading',
        (tester) async {
      await tester.pumpWidget(
          _host(PrimaryButton(text: 'Kirim', onTap: () {}, isLoading: true)));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Kirim'), findsNothing);
    });
  });

  group('AppTextButton', () {
    testWidgets('reports taps on its label', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
          _host(AppTextButton(label: 'Lupa?', onTap: () => taps++)));

      await tester.tap(find.text('Lupa?'));

      expect(taps, 1);
    });
  });

  group('PageIndicator', () {
    testWidgets('draws one dot per page', (tester) async {
      await tester.pumpWidget(_host(PageIndicator(length: 4, activeIndex: 2)));

      expect(find.byType(CircleAvatar), findsNWidgets(4));
    });
  });

  group('AppTextField', () {
    testWidgets('shows the label, hint and reports typing', (tester) async {
      final controller = TextEditingController();
      String? typed;
      await tester.pumpWidget(_host(AppTextField(
        controller: controller,
        label: 'Nama',
        hint: 'Isi nama',
        onChanged: (v) => typed = v,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      )));
      expect(find.text('Nama'), findsOneWidget);
      expect(find.text('Isi nama'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'a1b2');

      expect(typed, '12');
    });

    testWidgets('a label turns red when the field is in error', (tester) async {
      await tester.pumpWidget(_host(AppTextField(
        controller: TextEditingController(),
        label: 'Nama',
        hint: 'x',
        isError: true,
      )));

      expect(tester.widget<Text>(find.text('Nama')).style?.color, Colors.red);
    });

    testWidgets('a password field can reveal and hide its text',
        (tester) async {
      await tester.pumpWidget(_host(AppTextField(
        controller: TextEditingController(text: 'rahasia'),
        hint: 'Sandi',
        obscureText: true,
      )));
      expect(
          tester.widget<TextField>(find.byType(TextField)).obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();
      expect(tester.widget<TextField>(find.byType(TextField)).obscureText,
          isFalse);

      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();
      expect(
          tester.widget<TextField>(find.byType(TextField)).obscureText, isTrue);
    });
  });

  group('ForgotPasswordPage', () {
    testWidgets('formats the phone number and goes back on send',
        (tester) async {
      await pumpRouted(
        tester,
        // A non-const instance so the constructor itself runs.
        // ignore: prefer_const_constructors
        ForgotPasswordPage(),
        pushed: true,
      );
      expect(find.text('Lupa kata sandi?'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '081234567890');
      expect(find.text('0812-3456-7890'), findsOneWidget);

      await tester.tap(find.text('Kirim'));
      await tester.pumpAndSettle();

      expect(find.text('route:/'), findsOneWidget);
    });
  });
}
