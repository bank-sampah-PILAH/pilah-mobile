import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/logout_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';

class RoleHandoffPage extends StatelessWidget {
  final String title;
  final String message;
  final bool registrationInProgress;

  const RoleHandoffPage({
    super.key,
    required this.title,
    required this.message,
    required this.registrationInProgress,
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
    context.read<AuthenticationBloc>().add(LogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationStates>(
      listenWhen: (previous, current) => current is Unauthenticated,
      listener: (context, state) => context.go(LoginPage.route),
      child: Scaffold(
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
                  borderRadius: BorderRadius.circular(24),
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
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _changeAccount(context),
                        icon: const Icon(Icons.logout),
                        label: const Text('Keluar dan ganti akun'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: AppColors.greenDark,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
