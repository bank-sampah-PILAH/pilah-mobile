/// Settings for the analytics tool (PostHog), or `null` when analytics is off.
class AnalyticsConfig {
  const AnalyticsConfig({
    required this.apiKey,
    required this.host,
    required this.environment,
  });

  final String apiKey;
  final String host;
  final String environment;
}
