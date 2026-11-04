import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:pilah_mobile/services/di.dart';

/// The client for this build. Where none is registered (a test, or a build
/// without analytics) it is the no-op one, so the app behaves as if analytics
/// is off instead of failing, and nobody is ever recorded by accident.
final analyticsClientProvider = Provider<AnalyticsClient>((ref) =>
    di.isRegistered<AnalyticsClient>()
        ? di<AnalyticsClient>()
        : NoopAnalyticsClient());
