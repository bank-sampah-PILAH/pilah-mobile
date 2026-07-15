import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/core/router/auth_routing.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/check_session_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  static const route = '/splash';

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _isVisible = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Trigger fade-in animation shortly after render
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });

    // Restore any persisted session before deciding where to route.
    context.read<AuthenticationBloc>().add(CheckSessionRequested());
  }

  /// Routes based on the restored session. Fully onboarded users land on their
  /// dashboard; everyone else (no session, expired token, or onboarding not yet
  /// completed server-side) goes to login.
  void _handleState(BuildContext context, AuthenticationStates state) {
    if (_navigated) return;

    if (state is Authenticated) {
      _navigated = true;
      context.go(locationForAuthStep(
        state.authEntity.nextStep,
        hasPendingInvite: di<InviteTokenStore>().hasToken,
      ));
    } else if (state is Unauthenticated || state is AuthenticationFailure) {
      _navigated = true;
      context.go(LoginPage.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationStates>(
      listener: _handleState,
      // White, matching the native launch background (a plain white
      // launch_background.xml). The two are the same colour on purpose: this
      // page used to be greenDark, so launching showed a white native splash
      // and then a green Dart one — the "double splash". Same colour, one
      // apparent splash.
      child: Scaffold(
        backgroundColor: Colors.white,
        body: AnimatedOpacity(
          opacity: _isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          child: SafeArea(
            child: Stack(
              children: [
                // Center content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo — the same mark the login page shows, so the two
                      // brand moments match.
                      SvgPicture.asset(
                        'assets/svg/logo.svg',
                        height: 120,
                        semanticsLabel: 'Logo PILAH',
                      ),
                      const SizedBox(height: 24),
                      // PILAH text
                      Text(
                        'PILAH',
                        style: AppTextStyle.headline1.copyWith(
                          color: AppColors.greenDark,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Tagline
                      Text(
                        'Sistem Manajemen Bank Sampah',
                        style: AppTextStyle.small.copyWith(
                          color: AppColors.grey100,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Bottom content
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.greenDark,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Bank Sampah BTH, Depok',
                        style: AppTextStyle.extraSmall.copyWith(
                          color: AppColors.grey100,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
