import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/router/auth_routing.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/login_background_wrapper.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/login_button.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/login_footer.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/login_header.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/welcome_card.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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

          return LoginBackgroundWrapper(
            child: SafeArea(
              child: SingleChildScrollView(
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
                      const SizedBox(height: 48),
                      const LoginFooter(),
                      if (kDebugMode) ...[
                        const SizedBox(height: 48),
                        Text(
                          '--- Simulasi Role (Developer Only) ---',
                          style: TextStyle(
                            color: Colors.blueGrey.shade300,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: InkWell(
                            onTap: () {
                              context.go('/superadmin-dashboard');
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: CustomPaint(
                              painter: _DashedRectPainter(
                                color: Colors.blueGrey.shade200,
                                strokeWidth: 1.5,
                                gap: 6.0,
                                radius: 16.0,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                alignment: Alignment.center,
                                child: Text(
                                  'Masuk sebagai SuperAdmin',
                                  style: TextStyle(
                                    color: Colors.blueGrey.shade400,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double radius;

  _DashedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint dashedPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height), Radius.circular(radius)));

    Path dashPath = Path();

    double dashWidth = gap;
    double dashSpace = gap;
    double distance = 0.0;

    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth;
        distance += dashSpace;
      }
      distance = 0.0;
    }

    canvas.drawPath(dashPath, dashedPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
