import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:pilah_mobile/core/analytics/analytics_config.dart';

/// Outside the web there is no recorder yet, so analytics stays off.
AnalyticsClient createAnalyticsClient(AnalyticsConfig? config) =>
    NoopAnalyticsClient();
