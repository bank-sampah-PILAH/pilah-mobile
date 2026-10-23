import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/bases/widgets/app_confirm_dialog.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';

/// Asks whether to leave onboarding. On confirm it runs the standard logout,
/// which clears the session; the screen's own listener then sends the user to
/// the login page. Cancelling or dismissing leaves the form and its input
/// untouched. [title] names what is being left, since the profile step and the
/// registration steps word it differently.
Future<void> confirmExitOnboarding(
  BuildContext context, {
  String title = 'Keluar dari Pendaftaran?',
}) async {
  final shouldLogout = await showAppConfirmDialog(
    context,
    title: title,
    message:
        'Apakah Anda yakin ingin keluar? Progress pengisian data Anda belum '
        'tersimpan dan Anda akan dialihkan ke halaman login.',
    confirmLabel: 'Ya, Keluar',
    destructive: true,
  );
  if (shouldLogout && context.mounted) {
    ProviderScope.containerOf(context, listen: false)
        .read(authenticationProvider.notifier)
        .logout();
  }
}
