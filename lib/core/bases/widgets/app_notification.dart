import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

class AppNotification {
  static void showSuccess(BuildContext context, {required String title, required String message}) {
    Flushbar(
      titleText: Text(
        title, 
        style: AppTextStyle.title1.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      ),
      messageText: Text(
        message, 
        style: AppTextStyle.small.copyWith(color: Colors.white, fontSize: 12),
      ),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: AppColors.greenDark,
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      icon: const Icon(Icons.check_circle, color: Colors.white, size: 28),
      duration: const Duration(seconds: 3),
      boxShadows: [
        BoxShadow(color: Colors.black.withOpacity(0.1), offset: const Offset(0, 4), blurRadius: 10),
      ],
    ).show(context);
  }

  static void showError(BuildContext context, {required String title, required String message}) {
    Flushbar(
      titleText: Text(
        title, 
        style: AppTextStyle.title1.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      ),
      messageText: Text(
        message, 
        style: AppTextStyle.small.copyWith(color: Colors.white, fontSize: 12),
      ),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: const Color(0xFFDC2626), // error red
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      icon: const Icon(Icons.error_outline, color: Colors.white, size: 28),
      duration: const Duration(seconds: 4),
      boxShadows: [
        BoxShadow(color: Colors.black.withOpacity(0.1), offset: const Offset(0, 4), blurRadius: 10),
      ],
    ).show(context);
  }
}
