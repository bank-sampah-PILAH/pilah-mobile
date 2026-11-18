import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:pilah_mobile/core/analytics/analytics_config.dart';
import 'package:pilah_mobile/core/analytics/posthog_web_recording_client.dart';

/// On the web a configured build sends events through PostHog's browser
/// library, and records the screen with every text and image masked.
AnalyticsClient createAnalyticsClient(AnalyticsConfig? config) {
  if (config == null) return const NoopAnalyticsClient();
  return PosthogWebRecordingClient(
    apiKey: config.apiKey,
    host: config.host,
    environment: config.environment,
  );
}
