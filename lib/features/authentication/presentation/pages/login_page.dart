import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/client/app_environment.dart';
import 'package:pilah_mobile/core/router/auth_routing.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/login_background_wrapper.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/login_button.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/demo_login_button.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/demo_login_profile.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/login_footer.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/login_header.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/welcome_card.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/role_selection_page.dart';

class LoginPage extends StatelessWidget {
  @visibleForTesting
  final bool? debugShowDemoLogin;

  const LoginPage({super.key, this.debugShowDemoLogin});

  static const route = '/login';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthenticationBloc, AuthenticationStates>(
        listener: _handleAuthenticationState,
        builder: (context, state) => _buildLoginBody(state),
      ),
    );
  }

  void _handleAuthenticationState(
    BuildContext context,
    AuthenticationStates state,
  ) {
    if (state is Authenticated) {
      context.go(locationForAuthStep(
        state.authEntity.nextStep,
        hasPendingInvite: di<InviteTokenStore>().hasToken,
        role: state.authEntity.role,
      ));
    } else if (state is GoogleRegistrationPending) {
      context.go(RoleSelectionPage.route);
    } else if (state is AuthenticationFailure) {
      AppNotification.showError(
        context,
        title: 'Login Gagal',
        message: state.message,
      );
    }
  }

  Widget _buildLoginBody(AuthenticationStates state) {
    final isLoading = state is AuthenticationLoading;
    final environment =
        debugShowDemoLogin == null ? di<AppEnvironment>() : null;
    final demoLoginEnabled =
        !kReleaseMode && (debugShowDemoLogin ?? environment!.supportsDemoLogin);
    final demoProfiles = demoLoginEnabled && environment != null
        ? DemoLoginProfiles.forEnvironment(environment)
        : DemoLoginProfiles.all;

    return LoginBackgroundWrapper(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 1024) {
              return _DesktopLoginLayout(
                isLoading: isLoading,
                showDemoLogin: demoLoginEnabled,
                demoProfiles: demoProfiles,
              );
            }
            return _buildMobileLoginLayout(
              isLoading: isLoading,
              showDemoLogin: demoLoginEnabled,
              demoProfiles: demoProfiles,
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileLoginLayout({
    required bool isLoading,
    required bool showDemoLogin,
    required List<DemoLoginProfile> demoProfiles,
  }) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const LoginHeader(),
            const SizedBox(height: 48),
            const WelcomeCard(),
            const SizedBox(height: 32),
            LoginButton(isLoading: isLoading),
            if (showDemoLogin) ...[
              const SizedBox(height: 12),
              DemoLoginButton(
                isLoading: isLoading,
                profiles: demoProfiles,
              ),
            ],
            const SizedBox(height: 48),
            const LoginFooter(),
          ],
        ),
      ),
    );
  }
}

class _DesktopLoginLayout extends StatelessWidget {
  final bool isLoading;
  final bool showDemoLogin;
  final List<DemoLoginProfile> demoProfiles;

  const _DesktopLoginLayout({
    required this.isLoading,
    required this.showDemoLogin,
    required this.demoProfiles,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
            child: Center(
              child: ConstrainedBox(
                key: const ValueKey('desktop-login-content'),
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LoginHeader(),
                          SizedBox(height: 48),
                          WelcomeCard(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 64),
                    SizedBox(
                      width: 448,
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.greenLight),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.greenDark.withValues(alpha: 0.1),
                              blurRadius: 32,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Masuk ke akun Anda',
                              style: AppTextStyle.headline1.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Gunakan akun Google yang terdaftar untuk melanjutkan.',
                              style: AppTextStyle.small.copyWith(
                                color: AppColors.grey100,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Center(child: LoginButton(isLoading: isLoading)),
                            if (showDemoLogin) ...[
                              const SizedBox(height: 12),
                              DemoLoginButton(
                                isLoading: isLoading,
                                profiles: demoProfiles,
                              ),
                            ],
                            const SizedBox(height: 32),
                            const LoginFooter(),
                          ],
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
