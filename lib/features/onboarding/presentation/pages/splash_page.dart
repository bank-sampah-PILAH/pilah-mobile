import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/core/router/auth_routing.dart';
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
      context.go(locationForAuthStep(state.authEntity.nextStep));
    } else if (state is Unauthenticated || state is AuthenticationFailure) {
      _navigated = true;
      context.go(LoginPage.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationStates>(
      listener: _handleState,
      child: Scaffold(
        backgroundColor: AppColors.greenDark,
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
                      // Icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // PILAH text
                      Text(
                        'PILAH',
                        style: AppTextStyle.headline1.copyWith(
                          color: Colors.white,
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
                          color: Colors.white.withValues(alpha: 0.9),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Bank Sampah BTH, Depok',
                        style: AppTextStyle.extraSmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
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
