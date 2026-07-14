import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/forgot_password_page.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:pilah_mobile/features/harga/presentation/pages/harga_page.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/laporan/laporan_page.dart';
import 'package:pilah_mobile/features/main/presentation/pages/main_page.dart';

import 'package:pilah_mobile/features/nasabah/presentation/pages/nasabah_page.dart';

import 'package:pilah_mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/transaksi_baru_page.dart';

import 'package:pilah_mobile/features/onboarding/presentation/pages/complete_profile_screen.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/register_bank_sampah_screen.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/pending_approval_screen.dart';
import 'package:pilah_mobile/features/superadmin/presentation/pages/superadmin_dashboard_screen.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/splash_page.dart';

class AppRouterConfig {
  static final _parentKey = GlobalKey<NavigatorState>();
  
  static final GoRouter _router = GoRouter(
    initialLocation: SplashPage.route,
    navigatorKey: _parentKey,
    routes: <RouteBase>[
      GoRoute(
        path: SplashPage.route,
        name: SplashPage.route,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: LoginPage.route,
        name: LoginPage.route,
        builder: (context, state) => const LoginPage(),
      ),
      // Landing point for invite deep links. It renders nothing: it captures
      // the token and hands off to the normal session-restore flow, which sends
      // signed-out users to login first. Once signed in, the stored token is
      // what steers routing to the join screen.
      GoRoute(
        path: '/invite',
        redirect: (context, state) {
          final token = state.uri.queryParameters['token'];
          if (token != null) {
            di<InviteTokenStore>().save(token);
          }
          return SplashPage.route;
        },
      ),
      GoRoute(
        path: ForgotPasswordPage.route,
        name: ForgotPasswordPage.route,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: ProfilePage.route,
        name: ProfilePage.route,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: TransaksiBaruPage.route,
        name: TransaksiBaruPage.route,
        builder: (context, state) => const TransaksiBaruPage(),
      ),
      GoRoute(
        path: CompleteProfileScreen.route,
        name: CompleteProfileScreen.route,
        builder: (context, state) {
          // Invite mode is entirely driven by a token captured from a deep
          // link: with no token there is nothing to join with, so the screen is
          // a plain profile-completion form.
          return CompleteProfileScreen(
            isInviteMode: di<InviteTokenStore>().hasToken,
          );
        },
      ),
      GoRoute(
        path: RegisterBankSampahScreen.route,
        name: RegisterBankSampahScreen.route,
        builder: (context, state) => const RegisterBankSampahScreen(),
      ),
      GoRoute(
        path: PendingApprovalScreen.route,
        name: PendingApprovalScreen.route,
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: SuperAdminDashboardScreen.route,
        name: SuperAdminDashboardScreen.route,
        builder: (context, state) => const SuperAdminDashboardScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainPage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: DashboardPage.route,
                name: DashboardPage.route,
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: NasabahPage.route,
                name: NasabahPage.route,
                builder: (context, state) => const NasabahPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: HargaPage.route,
                name: HargaPage.route,
                builder: (context, state) => const HargaPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: LaporanPage.route,
                name: LaporanPage.route,
                builder: (context, state) => const LaporanPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  static GoRouter getRouter() => _router;
}
