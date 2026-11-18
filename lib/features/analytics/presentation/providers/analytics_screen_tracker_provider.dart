import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/analytics/analytics_screen_tracker.dart';
import 'package:pilah_mobile/core/router/app_router_config.dart';
import 'package:pilah_mobile/features/analytics/presentation/providers/analytics_client_provider.dart';

/// Reports the app's screens to analytics, for as long as it is read.
///
/// The app reads it once at its root so it listens from the start; the client
/// itself ignores everything until the user has agreed.
final analyticsScreenTrackerProvider = Provider<AnalyticsScreenTracker>(
  (ref) {
    final router = AppRouterConfig.getRouter();
    final tracker = AnalyticsScreenTracker(
      client: ref.watch(analyticsClientProvider),
      changes: router.routerDelegate,
      currentPath: () {
        final shown = router.routerDelegate.currentConfiguration;
        return shown.isEmpty ? null : shown.fullPath;
      },
    )..attach();
    ref.onDispose(tracker.dispose);
    return tracker;
  },
  dependencies: [analyticsClientProvider],
);
