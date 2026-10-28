import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

/// The look of a text field in the app's forms: white fill, 12px rounded
/// outline, green when focused and red on error.
///
/// The text of the field ([hintText], [errorText]) and what sits around it
/// ([prefixText], [prefixIcon], [suffixIcon]) are the only things that differ
/// from form to form. A label or helper line is rare: add it with
/// `copyWith(labelText: ...)` on the result. [hasError] paints the border red
/// without any message, for a field whose message is shown elsewhere, and
/// [focusColor] changes the focused border, for example red when rejecting.
InputDecoration appInputDecoration({
  String? hintText,
  String? errorText,
  String? prefixText,
  Widget? prefixIcon,
  Widget? suffixIcon,
  bool hasError = false,
  Color? focusColor,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    hintText: hintText,
    hintStyle: AppTextStyle.small.copyWith(color: AppColors.grey200),
    errorText: errorText,
    prefixText: prefixText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    enabledBorder: border(hasError ? AppColors.danger : AppColors.border),
    disabledBorder: border(AppColors.border),
    focusedBorder: border(
      hasError ? AppColors.danger : focusColor ?? AppColors.greenDark,
      1.5,
    ),
    errorBorder: border(AppColors.danger),
    focusedErrorBorder: border(AppColors.danger, 1.5),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

/// The look of a search field: a soft fill with no outline and a search icon.
InputDecoration appSearchDecoration({String? hintText}) => InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyle.small.copyWith(color: AppColors.grey200),
      prefixIcon: Icon(Icons.search, color: AppColors.grey200),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: BorderSide.none,
      ),
    );

/// A field with no border, for a value that sits inside a card, such as the
/// weight of a setoran item.
InputDecoration appBorderlessInputDecoration({String? hintText}) =>
    InputDecoration(
      hintText: hintText,
      border: InputBorder.none,
      contentPadding: const EdgeInsets.only(bottom: 12),
    );

/// Text style of what is typed into an [appInputDecoration] field.
TextStyle get appInputStyle =>
    AppTextStyle.small.copyWith(color: AppColors.black);
