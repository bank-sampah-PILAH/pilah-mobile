import 'package:pilah_mobile/features/authentication/presentation/pages/forgot_password_page.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouterConfig {
  static final _parentKey = GlobalKey<NavigatorState>();
  
  static final GoRouter _router = GoRouter(
    initialLocation: LoginPage.route,
    navigatorKey: _parentKey,
    routes: <RouteBase>[
      GoRoute(
          path: LoginPage.route,
          name: LoginPage.route,
          builder: (context, state) => const LoginPage()),
      GoRoute(
          path: ForgotPasswordPage.route,
          name: ForgotPasswordPage.route,
          builder: (context, state) => const ForgotPasswordPage()),
    ],
  );

  static GoRouter getRouter() => _router;
}
