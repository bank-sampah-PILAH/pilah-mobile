import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:pilah_mobile/features/analytics/presentation/providers/analytics_consent_provider.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';

import '../../../../support/auth_support.dart';

/// Screens and tests that never set analytics up must behave as if it is off,
/// and must not need dependency injection to know that.
void main() {
  ProviderContainer containerForPengurus() {
    final container = ProviderContainer(overrides: [
      authenticationProvider.overrideWith(() => TestAuthenticationNotifier(
            initialState: Authenticated(
              authEntity: AuthEntity(
                name: 'Sari',
                email: 'sari@example.test',
                photoUrl: '',
                token: 'token',
                role: 'pengelola',
              ),
            ),
          )),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('with nothing registered the client is the unavailable no-op one', () {
    final client = containerForPengurus().read(analyticsClientProvider);

    expect(client, isA<NoopAnalyticsClient>());
    expect(client.isAvailable, isFalse);
  });

  test('with nothing registered nobody is asked and nothing is switchable', () {
    final container = containerForPengurus();

    expect(container.read(analyticsNeedsPromptProvider), isFalse);
    expect(container.read(analyticsToggleVisibleProvider), isFalse);
  });
}
