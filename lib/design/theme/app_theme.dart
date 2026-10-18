import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';

Color? _dateForeground(Set<WidgetState> states, Color normal) {
  if (states.contains(WidgetState.disabled)) return AppColors.grey100;
  if (states.contains(WidgetState.selected)) return Colors.white;
  return normal;
}

Color? _selectedDateBackground(Set<WidgetState> states) =>
    states.contains(WidgetState.selected) ? AppColors.greenDark : null;

Color? _todayBackground(Set<WidgetState> states) {
  if (states.contains(WidgetState.disabled)) return null;
  return _selectedDateBackground(states) ?? AppColors.greenLight;
}

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
    final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md));
    // 14 rather than the 16 of headline3: two half-width buttons, such as
    // "Batal" and "Simpan Perubahan", must fit a phone.
    final label = AppTextStyle.headline3.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );
    const padding = EdgeInsets.symmetric(horizontal: 24, vertical: 12);
    return base.copyWith(
      // The Material default is a green-tinted off-white from the seed colour,
      // which made a screen that sets no background look unlike the rest.
      scaffoldBackgroundColor: Colors.white,
      // A dropdown's menu is painted in the canvas colour, which is the same
      // green-tinted off-white. White, like every other surface.
      canvasColor: Colors.white,
      // Hovered and keyboard-focused rows (a dropdown item, a popup item) get
      // the soft green of a hovered table row, not Material's grey.
      hoverColor: AppColors.greenLight.withValues(alpha: 0.45),
      focusColor: AppColors.greenLight.withValues(alpha: 0.45),
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
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
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
      // White and flat with a thin border, like every card of the dashboard and
      // Jadwal. Margin is up to the screen: the stock 4 pushes a card off the
      // grid.
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        headerBackgroundColor: AppColors.greenDark,
        headerForegroundColor: Colors.white,
        headerHeadlineStyle: AppTextStyle.headline1,
        headerHelpStyle: AppTextStyle.small,
        weekdayStyle: AppTextStyle.extraSmall.copyWith(
          color: AppColors.grey100,
          fontWeight: FontWeight.w600,
        ),
        dayStyle: AppTextStyle.small,
        dayForegroundColor: WidgetStateProperty.resolveWith(
          (states) => _dateForeground(states, AppColors.black),
        ),
        dayBackgroundColor:
            WidgetStateProperty.resolveWith(_selectedDateBackground),
        dayOverlayColor: WidgetStatePropertyAll(
          AppColors.greenDark.withValues(alpha: 0.08),
        ),
        todayForegroundColor: WidgetStateProperty.resolveWith(
          (states) => _dateForeground(states, AppColors.greenDark),
        ),
        todayBackgroundColor: WidgetStateProperty.resolveWith(_todayBackground),
        todayBorder: const BorderSide(color: AppColors.greenDark),
        yearStyle: AppTextStyle.small,
        yearForegroundColor: WidgetStateProperty.resolveWith(
          (states) => _dateForeground(states, AppColors.black),
        ),
        yearBackgroundColor:
            WidgetStateProperty.resolveWith(_selectedDateBackground),
        dividerColor: AppColors.border,
        cancelButtonStyle:
            TextButton.styleFrom(foregroundColor: AppColors.grey100),
        confirmButtonStyle:
            TextButton.styleFrom(foregroundColor: AppColors.greenDark),
      ),
    );
  }
}
