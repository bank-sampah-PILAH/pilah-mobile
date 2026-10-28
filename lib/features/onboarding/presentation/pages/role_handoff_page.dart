import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pilah_mobile/design/constants/font_size.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';

class RoleHandoffPage extends ConsumerWidget {
  final String title;
  final String message;
  final bool registrationInProgress;
  final bool showPayoutHistory;

  const RoleHandoffPage({
    super.key,
    required this.title,
    required this.message,
    required this.registrationInProgress,
    this.showPayoutHistory = false,
  });

  static const registerNasabahRoute = '/register-nasabah';
  static const nasabahDashboardRoute = '/nasabah-dashboard';
  static const registerIndukRoute = '/register-bank-sampah-induk';
  static const indukDashboardRoute = '/pengelola-induk-dashboard';

  Future<void> _changeAccount(BuildContext context) async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      if (!context.mounted) return;
      AppNotification.showError(
        context,
        title: 'Ganti Akun Gagal',
        message: 'Tidak dapat keluar dari akun Google. Silakan coba lagi.',
      );
      return;
    }

    if (!context.mounted) return;
    ProviderScope.containerOf(context, listen: false)
        .read(authenticationProvider.notifier)
        .logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authenticationProvider, (previous, current) {
      if (current is Unauthenticated) context.go(LoginPage.route);
    });
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: const Text('PILAH'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Icon(
                      registrationInProgress
                          ? Icons.assignment_outlined
                          : Icons.check_circle_outline,
                      color: AppColors.greenDark,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTextStyle.headline1,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyle.small.copyWith(
                      color: AppColors.grey100,
                      fontSize: AppFontSize.md,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (showPayoutHistory) ...[
                    AppButton(
                      label: 'Riwayat Nasabah',
                      variant: AppButtonVariant.outlined,
                      icon: Icons.receipt_long_outlined,
                      onPressed: () => context.push(Uri(
                        path: AppLocations.history,
                        queryParameters: {'filter': 'pencairan'},
                      ).toString()),
                    ),
                    const SizedBox(height: 12),
                  ],
                  AppButton(
                    label: 'Keluar dan ganti akun',
                    icon: Icons.logout,
                    onPressed: () => _changeAccount(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
