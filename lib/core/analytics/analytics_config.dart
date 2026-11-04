import 'package:pilah_mobile/core/constants/secrets.dart';

/// Settings for the session-recording tool, or `null` when analytics is off.
class AnalyticsConfig {
  const AnalyticsConfig({
    required this.apiKey,
    required this.host,
    required this.environment,
  });

  final String apiKey;
  final String host;
  final String environment;

  static AnalyticsConfig? fromSecrets() {
    if (!Secret.analyticsEnabled) return null;
    // Enabled without a key would send nothing useful: stay off instead.
    if (Secret.posthogApiKey.isEmpty) return null;
    return AnalyticsConfig(
      apiKey: Secret.posthogApiKey,
      host: Secret.posthogHost,
      // Only the deploy script checks the name against the flavor, so a local
      // build may leave it empty; its events must still say where they came from.
      environment: Secret.posthogEnvironment.isEmpty
          ? 'local'
          : Secret.posthogEnvironment,
    );
  }
}
