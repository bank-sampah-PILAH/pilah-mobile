import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/client/app_environment.dart';
import 'package:pilah_mobile/core/router/auth_routing.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/design/widgets/app_field_label.dart';
import 'package:pilah_mobile/design/widgets/atom/app_text_field.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/login_background_wrapper.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/login_button.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/demo_login_button.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/demo_login_profile.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/login_footer.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/login_header.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/role_selection_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  @visibleForTesting
  final bool? debugShowDemoLogin;

  const LoginPage({super.key, this.debugShowDemoLogin});

  static const route = '/login';

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    ref.listen(authenticationProvider, (previous, state) {
      _handleAuthenticationState(context, state);
    });
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildLoginBody(ref.watch(authenticationProvider)),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
        widget.debugShowDemoLogin == null ? di<AppEnvironment>() : null;
    final demoLoginEnabled = !kReleaseMode &&
        (widget.debugShowDemoLogin ?? environment!.supportsDemoLogin);
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
                emailController: _emailController,
                passwordController: _passwordController,
              );
            }
            return _buildMobileLoginLayout(
              isLoading: isLoading,
              showDemoLogin: demoLoginEnabled,
              demoProfiles: demoProfiles,
              emailController: _emailController,
              passwordController: _passwordController,
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
    required TextEditingController emailController,
    required TextEditingController passwordController,
  }) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const LoginHeader(),
            const SizedBox(height: 40),
            LoginButton(isLoading: isLoading),
            const SizedBox(height: 16),
            _EmailPasswordLoginForm(
              isLoading: isLoading,
              emailController: emailController,
              passwordController: passwordController,
            ),
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
  final TextEditingController emailController;
  final TextEditingController passwordController;

  const _DesktopLoginLayout({
    required this.isLoading,
    required this.showDemoLogin,
    required this.demoProfiles,
    required this.emailController,
    required this.passwordController,
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
                        child: Center(child: LoginHeader(large: true))),
                    const SizedBox(width: 64),
                    SizedBox(
                      width: 448,
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
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
                              'Pilih Google atau gunakan email dan kata sandi yang terdaftar untuk melanjutkan.',
                              style: AppTextStyle.small.copyWith(
                                color: AppColors.grey100,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Center(child: LoginButton(isLoading: isLoading)),
                            const SizedBox(height: 16),
                            _EmailPasswordLoginForm(
                              isLoading: isLoading,
                              emailController: emailController,
                              passwordController: passwordController,
                            ),
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

class _EmailPasswordLoginForm extends StatefulWidget {
  final bool isLoading;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  const _EmailPasswordLoginForm({
    required this.isLoading,
    required this.emailController,
    required this.passwordController,
  });

  @override
  State<_EmailPasswordLoginForm> createState() =>
      _EmailPasswordLoginFormState();
}

class _EmailPasswordLoginFormState extends State<_EmailPasswordLoginForm> {
  String get _email => widget.emailController.text;
  String get _password => widget.passwordController.text;

  bool get _canSubmit =>
      !widget.isLoading && _email.trim().isNotEmpty && _password.isNotEmpty;

  void _submit() {
    if (!_canSubmit) return;
    FocusScope.of(context).unfocus();
    ProviderScope.containerOf(context, listen: false)
        .read(authenticationProvider.notifier)
        .postLogin(_email.trim(), _password);
  }

  void _updateInput(String _) => setState(() {});

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'ATAU',
                  style: AppTextStyle.extraSmall.copyWith(
                    color: AppColors.grey100,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.border)),
            ],
          ),
          const SizedBox(height: 24),
          const AppFieldLabel('EMAIL'),
          const SizedBox(height: 8),
          AppTextField(
            key: const ValueKey('login-email-field'),
            controller: widget.emailController,
            hint: 'Masukkan email Anda',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            onChanged: _updateInput,
          ),
          const SizedBox(height: 16),
          const AppFieldLabel('KATA SANDI'),
          const SizedBox(height: 8),
          AppTextField(
            key: const ValueKey('login-password-field'),
            controller: widget.passwordController,
            hint: 'Masukkan kata sandi',
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onChanged: _updateInput,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),
          AppButton(
            key: const ValueKey('login-email-submit'),
            label: 'Masuk dengan Email',
            onPressed: _canSubmit ? _submit : null,
            isLoading: widget.isLoading,
          ),
        ],
      ),
    );
  }
}
