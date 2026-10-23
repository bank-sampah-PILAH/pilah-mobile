import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/theme/app_theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/features/harga/presentation/providers/harga_provider.dart';
import 'package:pilah_mobile/features/jadwal/presentation/providers/jadwal_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/transaksi_provider.dart';
import 'package:pilah_mobile/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:pilah_mobile/features/dashboard/presentation/providers/recent_activity_provider.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/providers/nasabah_pengumuman_provider.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/providers/pengumuman_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/riwayat_aktivitas_provider.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';
import 'package:pilah_mobile/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:pilah_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_approval_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/router/auth_routing.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/core/router/pending_invite.dart';

import 'package:pilah_mobile/services/di.dart';
import 'core/router/app_router_config.dart';

String browserTitleForPath(String path) {
  final words = path
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .join(' ')
      .replaceAll(RegExp(r'[-_]'), ' ')
      .split(RegExp(r'\s+'));
  final pageName = words
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
  return 'PILAH | ${pageName.isEmpty ? 'Beranda' : pageName}';
}

class _BrowserTitleUpdater extends StatefulWidget {
  const _BrowserTitleUpdater({
    required this.router,
    required this.enabled,
    required this.child,
  });

  final GoRouter router;
  final bool enabled;
  final Widget child;

  @override
  State<_BrowserTitleUpdater> createState() => _BrowserTitleUpdaterState();
}

class _BrowserTitleUpdaterState extends State<_BrowserTitleUpdater> {
  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      widget.router.routeInformationProvider.addListener(_scheduleUpdate);
      _scheduleUpdate();
    }
  }

  void _scheduleUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.enabled) return;
      SystemChrome.setApplicationSwitcherDescription(
        ApplicationSwitcherDescription(
          label: browserTitleForPath(
            widget.router.routeInformationProvider.value.uri.path,
          ),
          primaryColor: AppColors.primary.toARGB32(),
        ),
      );
    });
  }

  @override
  void dispose() {
    widget.router.routeInformationProvider.removeListener(_scheduleUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class App extends StatelessWidget {
  // The constructor line is only credited when the first coverage report merged
  // for this file happens to be from the test that builds `const App()` (the
  // merge keeps the first value seen), so it is excluded to stay deterministic.
  @visibleForTesting
  final bool? isWebOverride;

  @visibleForTesting
  final Widget Function(Widget child)? providerScopeBuilder;

  const App({
    super.key,
    @visibleForTesting this.isWebOverride,
    @visibleForTesting this.providerScopeBuilder,
  }); // coverage:ignore-line

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final isWeb = isWebOverride ?? kIsWeb;
    final router = AppRouterConfig.getRouter();
    final app = Consumer(
      builder: (context, ref, child) {
        // Session hygiene belongs above the router so every logout and
        // rejected session resets user-scoped state, regardless of route.
        ref.listen(authenticationProvider, (previous, current) {
          AppRouterConfig.notifyAuthStateChanged();
          if (current is Unauthenticated) {
            resetSessionScopedState(context);
          }
          if (isWeb &&
              current is Authenticated &&
              !isSupportedWebRole(current.authEntity.role)) {
            ref.read(authenticationProvider.notifier).logout();
            AppNotification.afterNavigation(
              (context) => AppNotification.showWarning(
                context,
                title: 'Akses web tidak tersedia',
                message:
                    'Akun ini hanya dapat digunakan melalui aplikasi mobile.',
              ),
            );
          }
        });
        return _PendingInviteResumeWatcher(
          child: _BrowserTitleUpdater(
            router: router,
            enabled: isWeb,
            child: MaterialApp.router(
              title: isWeb ? 'PILAH | Beranda' : 'Flutter Pilah Mobile',
              theme: AppTheme.light,
              // Material widgets (date pickers, dialog buttons) in Indonesian.
              locale: const Locale('id'),
              supportedLocales: const [Locale('id')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: router,
            ),
          ),
        );
      },
    );
    return providerScopeBuilder?.call(app) ?? ProviderScope(child: app);
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
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _routeToPendingInvite());
  }

  void _routeToPendingInvite() {
    if (!mounted) return;
    if (!di<InviteTokenStore>().hasToken) return;

    final authState = ProviderScope.containerOf(context, listen: false)
        .read(authenticationProvider);
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
  final providers = ProviderScope.containerOf(context, listen: false);
  if (providers.exists(nasabahProvider)) {
    providers.read(nasabahProvider.notifier).reset();
  }
  if (providers.exists(hargaProvider)) {
    providers.read(hargaProvider.notifier).reset();
  }
  providers.read(jadwalProvider.notifier).reset();
  if (providers.exists(pengumumanProvider)) {
    providers.read(pengumumanProvider.notifier).reset();
  }
  if (providers.exists(nasabahPengumumanProvider)) {
    providers.read(nasabahPengumumanProvider.notifier).reset();
  }
  providers
    ..invalidate(pengumumanProvider)
    ..invalidate(nasabahPengumumanProvider);
  if (providers.exists(transaksiProvider)) {
    providers.read(transaksiProvider.notifier).reset();
  }
  providers.invalidate(dashboardProvider);
  providers.invalidate(recentActivityProvider);
  if (providers.exists(riwayatAktivitasProvider)) {
    providers.read(riwayatAktivitasProvider.notifier).reset();
  }
  // Carries the previous bank sampah's WhatsApp template and, more sensitively,
  // any logo picked but not yet uploaded — a path into that user's gallery.
  if (providers.exists(profileProvider)) {
    providers.read(profileProvider.notifier).reset();
    providers.invalidate(profileProvider);
  }
  providers.invalidate(nasabahApprovalProvider);
  // The half-filled registration profile, unlike the invite token below, is
  // squarely session-scoped: it is one person's name, phone and date of birth.
  // Left behind it would prefill the next account's form with a stranger's
  // details, and worse, `submitRegistration` would send them under that
  // account's credentials.
  if (providers.exists(onboardingProvider)) {
    providers.read(onboardingProvider.notifier).clearProfileDraft();
  }
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
