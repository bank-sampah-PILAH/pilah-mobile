import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/client/app_environment.dart';
import 'package:pilah_mobile/core/router/auth_routing.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
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
        listener: (context, state) {
          if (state is Authenticated) {
            context.go(locationForAuthStep(
              state.authEntity.nextStep,
              hasPendingInvite: di<InviteTokenStore>().hasToken,
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
        },
        builder: (context, state) {
          final isLoading = state is AuthenticationLoading;
          final environment =
              debugShowDemoLogin == null ? di<AppEnvironment>() : null;
          final demoLoginEnabled = !kReleaseMode &&
              (debugShowDemoLogin ?? environment!.supportsDemoLogin);

          return LoginBackgroundWrapper(
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 48.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const LoginHeader(),
                      const SizedBox(height: 48),
                      const WelcomeCard(),
                      const SizedBox(height: 32),
                      LoginButton(isLoading: isLoading),
                      if (demoLoginEnabled) ...[
                        const SizedBox(height: 12),
                        DemoLoginButton(
                          isLoading: isLoading,
                          profiles: environment == null
                              ? DemoLoginProfiles.all
                              : DemoLoginProfiles.forEnvironment(environment),
                        ),
                      ],
                      const SizedBox(height: 48),
                      const LoginFooter(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
