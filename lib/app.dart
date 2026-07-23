import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/core/router/pending_invite.dart';

import 'package:pilah_mobile/services/di.dart';
import 'core/router/app_router_config.dart';

class App extends StatelessWidget {
  const App({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Cubits load their data from each page's initState (post-login), so
        // the requests carry the authenticated session instead of firing once
        // at cold start before a token exists.
        BlocProvider<NasabahCubit>(
          create: (context) => di<NasabahCubit>(),
        ),
        BlocProvider<HargaCubit>(
          create: (context) => di<HargaCubit>(),
        ),
        BlocProvider<TransaksiCubit>(
          create: (context) => di<TransaksiCubit>(),
        ),
        BlocProvider<DashboardCubit>(
          create: (context) => di<DashboardCubit>(),
        ),
        BlocProvider<AuthenticationBloc>(
          create: (context) => di<AuthenticationBloc>(),
        ),
        BlocProvider<OnboardingCubit>(
          create: (context) => di<OnboardingCubit>(),
        ),
      ],
      // Session hygiene for the app-scoped (@lazySingleton) cubits. These
      // outlive any one session, so without this the next user to log in
      // inherits the previous one's cached lists and stats.
      //
      // It lives at the root, above the router, on purpose: `Unauthenticated`
      // is emitted by an explicit logout *and* by a rejected/expired session on
      // startup, from whichever screen happens to be on top. A listener tied to
      // a single page only runs while that page is mounted, which silently
      // misses every other exit path.
      child: BlocListener<AuthenticationBloc, AuthenticationStates>(
        listenWhen: (previous, current) => current is Unauthenticated,
        listener: (context, state) => resetSessionScopedState(context),
        child: _PendingInviteResumeWatcher(
          child: MaterialApp.router(
            title: 'Flutter Pilah Mobile',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
              ),
              useMaterial3: true,
            ),
            routerConfig: AppRouterConfig.getRouter(),
          ),
        ),
      ),
    );
  }

}

/// Re-checks for a pending invite every time the app comes to the foreground.
///
/// The router's own redirect already prioritises a banked token on any routing
/// pass, and an invite link tapped from outside the app is one. This is the
/// backstop for when it isn't: an invite that was captured but left unredeemed
/// (the tap arrived while the session was expiring, the process was killed
/// mid-flow, the link was tapped twice) otherwise sits in the store doing
/// nothing until the user happens to navigate.
///
/// Inert without a token, and inert for accounts that cannot redeem one — see
/// [pendingInviteLocation].
class _PendingInviteResumeWatcher extends StatefulWidget {
  const _PendingInviteResumeWatcher({required this.child});

  final Widget child;

  @override
  State<_PendingInviteResumeWatcher> createState() =>
      _PendingInviteResumeWatcherState();
}

class _PendingInviteResumeWatcherState
    extends State<_PendingInviteResumeWatcher> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // One frame of slack: on Android the new intent is delivered before resume,
    // but the platform route push that carries `/invite?token=…` into the router
    // still has to land before the store can be asked about it.
    WidgetsBinding.instance.addPostFrameCallback((_) => _routeToPendingInvite());
  }

  void _routeToPendingInvite() {
    if (!mounted) return;
    if (!di<InviteTokenStore>().hasToken) return;

    final authState = context.read<AuthenticationBloc>().state;
    if (authState is! Authenticated) return;

    final target = resolvePendingInvite(
      step: authState.authEntity.nextStep,
      role: authState.authEntity.role,
    );
    if (target == null) return;

    // `currentConfiguration` rather than `GoRouter.state`: the latter reads
    // `matches.last` and throws before the router has resolved anything, and a
    // resume handler is not a place to risk that.
    final router = AppRouterConfig.getRouter();
    if (router.routerDelegate.currentConfiguration.uri.path == target) return;
    router.go(target);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Clears all state that outlives a single session, on logout or a
/// rejected/expired session. Top-level so it can be exercised directly in tests
/// rather than only through the full [App] widget tree.
void resetSessionScopedState(BuildContext context) {
  context.read<NasabahCubit>().reset();
  context.read<HargaCubit>().reset();
  context.read<TransaksiCubit>().reset();
  context.read<DashboardCubit>().reset();
  // The half-filled registration profile, unlike the invite token below, is
  // squarely session-scoped: it is one person's name, phone and date of birth.
  // Left behind it would prefill the next account's form with a stranger's
  // details, and worse, `submitRegistration` would send them under that
  // account's credentials.
  context.read<OnboardingCubit>().clearProfileDraft();
  // A pending invite token is deliberately NOT cleared here.
  //
  // Logging out is a step *inside* the invite flow, not an exit from it:
  // invites are sent to a specific person, and the account that happens to be
  // signed in when the link is tapped is routinely the wrong one. Wiping the
  // token on logout meant the deliberate "switch to the invited account" — and
  // any session that merely expired mid-flow — dropped the invite silently, and
  // the user had to find the link and tap it again.
  //
  // The trade-off is accepted knowingly: the token now survives until it is
  // redeemed or explicitly refused, so an invite captured and abandoned by one
  // account can be picked up by the next account signed in on this device. It
  // is short-lived in practice — the invite gate spends it on the very first
  // redemption attempt, whatever the backend answers.
}
