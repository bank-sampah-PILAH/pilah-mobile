import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/router/root_navigator_key.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

class AppNotification {
  /// Warning tone: a light amber tint carrying dark amber content.
  ///
  /// Deliberately unlike the two solid fills. Success and error are verdicts on
  /// what the user just did; a warning is an aside about something that went a
  /// different way than expected but cost them nothing. The tint reads quieter
  /// than either, and the border supplies the edge the solid fill would.
  static const Color _warningBackground = Color(0xFFFEF3C7);
  static const Color _warningForeground = Color(0xFFD97706);

  /// One elevation shared by all three tones, so they read as the same
  /// component wearing different colours.
  static final List<BoxShadow> _shadow = List.unmodifiable([
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      offset: const Offset(0, 4),
      blurRadius: 10,
    ),
  ]);

  /// Raises a toast against the root navigator, once the navigation issued
  /// alongside it has actually landed.
  ///
  /// [Flushbar] shows itself by pushing a route. A route pushed on top of the
  /// page a `context.go(...)` is in the middle of replacing is torn down with
  /// that page — the toast flashes and vanishes, and the two overlapping
  /// Navigator mutations are what surfaced as duplicate-GlobalKey crashes on
  /// the invite redirects.
  ///
  /// Two frames, deliberately: the first ends the frame the caller navigated
  /// in, and the router only rebuilds its Navigator on the frame after that. By
  /// the second, the destination page exists and the toast attaches to it.
  /// Callers navigate first, then hand the toast to this.
  static void afterNavigation(void Function(BuildContext context) show) {
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      binding.addPostFrameCallback((_) {
        final context = rootNavigatorKey.currentContext;
        // No navigator: the app is tearing down, or this is a test running
        // without the real router. A dropped toast beats an exception.
        if (context == null) return;
        show(context);
      });
      // The caller may not have navigated (a failure that keeps the user on the
      // form), in which case nothing else guarantees a second frame.
      binding.scheduleFrame();
    });
  }

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
      boxShadows: _shadow,
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
      boxShadows: _shadow,
    ).show(context);
  }

  /// The neutral tone, for a valid action whose outcome was simply not the one
  /// the user was reaching for — an "already done" result, or a side-effect that
  /// failed without costing them the main one. Nothing is broken and nothing
  /// needs redoing, so neither `showSuccess` nor `showError` tells the truth.
  ///
  /// Held for the same four seconds as [showError]: a warning carries something
  /// worth reading, unlike a success that only confirms what the user expected.
  static void showWarning(BuildContext context, {required String title, required String message}) {
    Flushbar(
      titleText: Text(
        title,
        style: AppTextStyle.title1.copyWith(color: _warningForeground, fontWeight: FontWeight.bold, fontSize: 14),
      ),
      messageText: Text(
        message,
        style: AppTextStyle.small.copyWith(color: _warningForeground, fontSize: 12),
      ),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: _warningBackground,
      borderColor: _warningForeground,
      borderWidth: 1,
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      icon: const Icon(Icons.warning_amber_rounded, color: _warningForeground, size: 28),
      duration: const Duration(seconds: 4),
      boxShadows: _shadow,
    ).show(context);
  }
}
