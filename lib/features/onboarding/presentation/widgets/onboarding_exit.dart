import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_confirm_dialog.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';

/// Asks whether to leave onboarding. On confirm it runs the standard logout,
/// which clears the session; the screen's own listener then sends the user to
/// the login page. Cancelling or dismissing leaves the form and its input
/// untouched. [title] names what is being left, since the profile step and the
/// registration steps word it differently.
///
/// When [discardAccount] is true the flow deletes a fresh registration
/// account (profile incomplete, nothing attached) before logging out, so the
/// next sign-in offers the role choice again (UAT 2026-11). A refusal keeps
/// the confirm dialog's promise loose: the message explains why and the
/// session is simply logged out.
Future<void> confirmExitOnboarding(
  BuildContext context, {
  String title = 'Keluar dari Pendaftaran?',
  bool discardAccount = false,
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
  if (!shouldLogout || !context.mounted) return;
  final provider = ProviderScope.containerOf(context, listen: false)
      .read(authenticationProvider.notifier);
  if (discardAccount) {
    await provider.discardRegistration(
      // A refusal ends the session anyway, so the router is already heading to
      // the login page; the toast must ride afterNavigation to survive both
      // the page teardown and that redirect (same lesson as CPBI-21).
      onError: (message) => AppNotification.afterNavigation(
        (context) => AppNotification.showError(
          context,
          title: 'Akun Tidak Dihapus',
          message: message,
        ),
      ),
    );
    return;
  }
  provider.logout();
}

void handleOnboardingStepPop(
  BuildContext context, {
  required bool didPop,
  required bool isWizardStep,
}) {
  if (didPop) return;
  if (!isWizardStep) {
    confirmExitOnboarding(context);
    return;
  }
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
  } else {
    context.go('/complete-profile');
  }
}
