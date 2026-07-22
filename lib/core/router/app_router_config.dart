import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/core/router/pending_invite.dart';
import 'package:pilah_mobile/core/router/root_navigator_key.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
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
import 'package:pilah_mobile/features/onboarding/presentation/pages/invite_gate_page.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/register_bank_sampah_screen.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/pending_approval_screen.dart';
import 'package:pilah_mobile/features/superadmin/presentation/pages/superadmin_dashboard_screen.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/splash_page.dart';

class AppRouterConfig {
  static final GoRouter _router = GoRouter(
    initialLocation: SplashPage.route,
    navigatorKey: rootNavigatorKey,
    // Global redirect: bank an incoming invite token, then act on it.
    //
    // It runs before any route-level redirect for every incoming URI —
    // including the very first one when a deep link cold-starts the app — so
    // an `/invite?token=…` token is captured before anything can route the user
    // elsewhere.
    //
    // Capturing and prioritising deliberately happen in the same pass. go_router
    // 17 runs this top-level redirect *at most once per navigation*, before
    // route-level redirects and never again on whatever it resolves to (see
    // `RouteConfiguration.applyTopLegacyRedirect`), so there is no second pass
    // to defer the decision to. Banking the token here and hoping a later
    // evaluation picks it up is precisely how a warm-start invite used to be
    // swallowed: the tap landed on `/invite`, the token was stored, the route
    // handed off to the splash, and an already-signed-in user was put straight
    // back on their dashboard without `POST /invites/accept` ever being called.
    //
    // Where to go stays with [locationForAuthStep]; this only decides *whether*
    // the invite outranks wherever the user was headed.
    redirect: (context, state) {
      final path = state.uri.path;

      if (path == '/invite') {
        final token = state.uri.queryParameters['token'];
        if (token != null) {
          di<InviteTokenStore>().save(token);
        }
      }

      final store = di<InviteTokenStore>();
      if (!store.hasToken) return null;

      // No session yet (signed out, or a cold start still restoring one): the
      // token keeps until there is an account to redeem it with, and `/invite`
      // falls through to its own redirect → splash → login. The login and
      // splash flows re-check the store once they have a user.
      final authState = context.read<AuthenticationBloc>().state;
      if (authState is! Authenticated) return null;

      // `null` means this account can't redeem an invite at all (superadmin) —
      // in which case the token is dropped here rather than left to follow the
      // next account onto this device. See [resolvePendingInvite].
      final target = resolvePendingInvite(
        step: authState.authEntity.nextStep,
        role: authState.authEntity.role,
      );
      if (target == null || target == path) return null;
      return target;
    },
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
      // Landing point for invite deep links, reached only when there is no
      // session yet: an already-signed-in user is sent to the redemption screen
      // by the global redirect above and never gets here. It renders nothing and
      // captures nothing — the token is already banked by the time this runs —
      // and only hands off to the session-restore flow, which routes a signed-out
      // user to login. The stored token then steers them onward from there.
      GoRoute(
        path: '/invite',
        redirect: (context, state) => SplashPage.route,
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
        path: InviteGatePage.route,
        name: InviteGatePage.route,
        pageBuilder: (context, state) => MaterialPage(
          // Keyed by the token, not by the path. The gate redeems once, from
          // initState; a second invite tapped while the first is still in
          // flight resolves to this same location, and an unkeyed page would be
          // reused rather than remounted — leaving the newer token banked and
          // the user on a spinner that never resolves.
          key: ValueKey('invite-gate-${di<InviteTokenStore>().token ?? ''}'),
          child: const InviteGatePage(),
        ),
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
        builder: (context, state) {
          // Re-application mode: the user reached this form because their
          // previous registration was rejected (bank_sampah_status ==
          // 'rejected'), not as a first-time onboarding step. The screen reads
          // the flag to swap the stepper for a rejection notice.
          final authState = context.read<AuthenticationBloc>().state;
          final isRejected = authState is Authenticated &&
              authState.authEntity.bankSampahStatus == 'rejected';
          return RegisterBankSampahScreen(isRejectedReapplication: isRejected);
        },
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
