import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';

/// The app's [ThemeData], so a stock Material widget looks like the rest of
/// the app without every screen restyling it.
abstract final class AppTheme {
  static final ThemeData light = _build();

  static ThemeData _build() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.greenDark,
      ).copyWith(primary: AppColors.greenDark),
    );
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    // 14 rather than the 16 of headline3: two half-width buttons, such as
    // "Batal" and "Simpan Perubahan", must fit a phone.
    final label = AppTextStyle.headline3.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );
    const padding = EdgeInsets.symmetric(horizontal: 24, vertical: 12);
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.black,
        titleTextStyle: AppTextStyle.appBar,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      // A plain Material button looks like an `AppButton`: green, flat, rounded
      // 12. Only the sizing and the red/grey variants live in `AppButton`.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.greenDark,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.grey100,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: shape,
          textStyle: label,
          padding: padding,
          minimumSize: const Size(64, AppButton.height),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.greenDark,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.grey100,
          elevation: 0,
          shape: shape,
          textStyle: label,
          padding: padding,
          minimumSize: const Size(64, AppButton.height),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.greenDark,
          disabledForegroundColor: AppColors.grey100,
          side: const BorderSide(color: AppColors.greenDark, width: 1.5),
          shape: shape,
          textStyle: label,
          padding: padding,
          minimumSize: const Size(64, AppButton.height),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
