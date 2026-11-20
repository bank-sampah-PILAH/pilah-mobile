import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/form_style.dart';
import 'package:pilah_mobile/design/theme/app_theme.dart';
import 'package:pilah_mobile/design/widgets/phone_prefix.dart';

OutlineInputBorder _outline(InputBorder? border) =>
    border! as OutlineInputBorder;

void main() {
  group('appInputDecoration', () {
    test('is a white, 12 rounded field with a green focus', () {
      final decoration = appInputDecoration(hintText: 'Nama');

      expect(decoration.hintText, 'Nama');
      expect(decoration.filled, isTrue);
      expect(decoration.fillColor, Colors.white);
      expect(
        _outline(decoration.enabledBorder).borderRadius,
        BorderRadius.circular(12),
      );
      expect(
        _outline(decoration.focusedBorder).borderSide.color,
        AppColors.greenDark,
      );
    });

    test('passes the hint, error, prefix and suffix through', () {
      const suffix = Icon(Icons.calendar_month);
      final decoration = appInputDecoration(
        hintText: 'Contoh: 50000',
        errorText: 'Terlalu besar',
        prefixText: 'Rp ',
        suffixIcon: suffix,
      );

      expect(decoration.hintText, 'Contoh: 50000');
      expect(decoration.errorText, 'Terlalu besar');
      expect(decoration.prefixText, 'Rp ');
      expect(decoration.suffixIcon, suffix);
    });

    test('paints errors in the AA danger red, not a stock red', () {
      final decoration = appInputDecoration();

      expect(
          _outline(decoration.errorBorder).borderSide.color, AppColors.danger);
      expect(_outline(decoration.focusedErrorBorder).borderSide.color,
          AppColors.danger);
    });

    test('hasError turns the border red without any message', () {
      final decoration = appInputDecoration(hasError: true);

      expect(_outline(decoration.enabledBorder).borderSide.color,
          AppColors.danger);
      expect(_outline(decoration.focusedBorder).borderSide.color,
          AppColors.danger);
    });

    test('focusColor changes only the focused border', () {
      final decoration = appInputDecoration(focusColor: AppColors.danger);

      expect(_outline(decoration.focusedBorder).borderSide.color,
          AppColors.danger);
      expect(_outline(decoration.enabledBorder).borderSide.color,
          isNot(AppColors.danger));
    });
  });

  group('appSearchDecoration', () {
    test('is a filled, borderless, 16 rounded field with a search icon', () {
      final decoration = appSearchDecoration(hintText: 'Cari nama...');

      expect(decoration.hintText, 'Cari nama...');
      expect(decoration.filled, isTrue);
      expect(decoration.prefixIcon, isA<Icon>());
      final border = _outline(decoration.border);
      expect(border.borderRadius, BorderRadius.circular(16));
      expect(border.borderSide, BorderSide.none);
    });
  });

  group('appBorderlessInputDecoration', () {
    test('has no border, for a value that sits inside a card', () {
      final decoration = appBorderlessInputDecoration();

      expect(decoration.border, InputBorder.none);
      expect(decoration.contentPadding, const EdgeInsets.only(bottom: 12));
    });
  });

  group('PhonePrefix', () {
    testWidgets('shows +62 and a divider before the number', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: Center(child: PhonePrefix())),
      ));

      expect(find.text('+62'), findsOneWidget);
      expect(
        tester.getCenter(find.text('+62')).dx,
        lessThan(tester.getCenter(find.byKey(const Key('phone-divider'))).dx),
      );
    });
  });
}
