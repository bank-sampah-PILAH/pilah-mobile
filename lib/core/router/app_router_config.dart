import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/forgot_password_page.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:pilah_mobile/features/harga/presentation/pages/harga_page.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/laporan/laporan_page.dart';
import 'package:pilah_mobile/features/main/presentation/pages/main_page.dart';

import 'package:pilah_mobile/features/nasabah/presentation/pages/nasabah_page.dart';

import 'package:pilah_mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/transaksi_baru_page.dart';

class AppRouterConfig {
  static final _parentKey = GlobalKey<NavigatorState>();
  
  static final GoRouter _router = GoRouter(
    initialLocation: LoginPage.route,
    navigatorKey: _parentKey,
    routes: <RouteBase>[
      GoRoute(
        path: LoginPage.route,
        name: LoginPage.route,
        builder: (context, state) => const LoginPage(),
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
