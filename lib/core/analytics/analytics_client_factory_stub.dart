import 'package:flutter/foundation.dart';
import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:pilah_mobile/core/analytics/analytics_config.dart';
import 'package:pilah_mobile/core/analytics/posthog_mobile_client.dart';

/// On Android and iOS a configured build sends events through PostHog's native
/// SDK; on any other platform analytics stays off.
AnalyticsClient createAnalyticsClient(AnalyticsConfig? config) {
  final native = defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  if (config == null || !native) return const NoopAnalyticsClient();
  return PosthogMobileClient(
    apiKey: config.apiKey,
    host: config.host,
    environment: config.environment,
  );
}
