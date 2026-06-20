import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_primary_button.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/login_with_google_events.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static const route = '/login';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocConsumer<AuthenticationBloc, AuthenticationStates>(
          listener: (context, state) {
            if (state is Authenticated) {
              context.go('/dashboard');
            } else if (state is AuthenticationFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthenticationLoading;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),
                  // PILAH Logo Placeholder
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.eco,
                      size: 60,
                      color: AppColors.greenDark,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Headline
                  Text(
                    "Sistem Manajemen\nBank Sampah Digital",
                    textAlign: TextAlign.center,
                    style: AppTextStyle.headline1.copyWith(
                      color: AppColors.greenDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Indicator
                  Text(
                    "Hanya untuk Petugas & Admin terdaftar",
                    style: AppTextStyle.small.copyWith(
                      color: AppColors.grey100,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Login with Google Button
                  if (isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.greenDark),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: CustomPrimaryButton(
                        title: "Login dengan Google",
                        icon: Icons.g_mobiledata_rounded,
                        color: Colors.white,
                        textColor: Colors.black87,
                        onPressed: () {
                          context.read<AuthenticationBloc>().add(
                                LoginWithGoogleRequested(
                                  idToken: 'dummy_google_token_123',
                                ),
                              );
                        },
                      ),
                    ),
                  const Spacer(),
                  // Footer text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: AppColors.grey100,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Aman & Terenkripsi",
                        style: AppTextStyle.extraSmall.copyWith(
                          color: AppColors.grey100,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
