import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:pilah_mobile/core/analytics/analytics_config.dart';

/// Picks the client for this platform: the no-op one when analytics is off.
AnalyticsClient createAnalyticsClient(AnalyticsConfig? config) =>
    NoopAnalyticsClient();
