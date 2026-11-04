import 'package:pilah_mobile/core/analytics/analytics_config.dart';
import 'package:pilah_mobile/core/constants/secrets.dart';

/// The analytics settings of this build, or `null` when analytics is off.
///
/// Kept apart from [AnalyticsConfig] so code that only needs the settings (the
/// web client factory) does not pull in the env file, which plain `dart test`
/// cannot compile for the browser.
AnalyticsConfig? analyticsConfigFromSecrets() {
  if (!Secret.analyticsEnabled) return null;
  // Enabled without a key would send nothing useful: stay off instead.
  if (Secret.posthogApiKey.isEmpty) return null;
  return AnalyticsConfig(
    apiKey: Secret.posthogApiKey,
    host: Secret.posthogHost,
    environment:
        Secret.posthogEnvironment.isEmpty ? 'local' : Secret.posthogEnvironment,
  );
}
