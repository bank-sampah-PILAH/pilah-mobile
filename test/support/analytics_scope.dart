import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/features/analytics/presentation/providers/analytics_consent_provider.dart';

import 'fake_analytics_client.dart';

/// [app] inside a scope where analytics is a recording fake, for widgets that
/// report what the pengurus did but are not under test for it.
Widget withAnalytics(Widget app, {FakeAnalyticsClient? client}) =>
    ProviderScope(
      overrides: [
        analyticsClientProvider
            .overrideWithValue(client ?? FakeAnalyticsClient()),
      ],
      child: app,
    );
