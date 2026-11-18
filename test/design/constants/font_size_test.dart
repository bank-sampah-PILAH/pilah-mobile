import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/constants/font_size.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

void main() {
  test('the font size scale is 10, 12, 14, 16, 18, 20 and 24', () {
    expect(
      [
        AppFontSize.xs,
        AppFontSize.sm,
        AppFontSize.md,
        AppFontSize.lg,
        AppFontSize.xl,
        AppFontSize.xxl,
        AppFontSize.display,
      ],
      [10, 12, 14, 16, 18, 20, 24],
    );
  });

  test('a figure and a splash mark are larger than any text step', () {
    expect(AppFontSize.figure, 28);
    expect(AppFontSize.jumbo, 48);
    expect(AppFontSize.figure, greaterThan(AppFontSize.display));
    expect(AppFontSize.jumbo, greaterThan(AppFontSize.figure));
  });

  test('the text styles are built from the scale', () {
    expect(AppTextStyle.extraSmall.fontSize, AppFontSize.xs);
    expect(AppTextStyle.small.fontSize, AppFontSize.sm);
    expect(AppTextStyle.headline3.fontSize, AppFontSize.lg);
    expect(AppTextStyle.title1.fontSize, AppFontSize.xl);
    expect(AppTextStyle.appBar.fontSize, AppFontSize.xl);
    expect(AppTextStyle.headline1.fontSize, AppFontSize.display);
  });
}
