import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/analytics/presentation/providers/analytics_consent_provider.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';

import '../../../../support/auth_support.dart';

Authenticated _signedInAs(String? role) => Authenticated(
      authEntity: AuthEntity(
        name: 'Tester',
        email: 'tester@example.com',
        photoUrl: '',
        token: 'token',
        role: role,
      ),
    );

ProviderContainer _containerFor(AuthenticationStates state) {
  final container = ProviderContainer(overrides: [
    authenticationProvider
        .overrideWith(() => TestAuthenticationNotifier(initialState: state)),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('only pengurus roles may be recorded', () {
    expect(
        _containerFor(_signedInAs('pengelola')).read(analyticsEligibleProvider),
        isTrue);
    expect(
        _containerFor(_signedInAs('pengelola_induk'))
            .read(analyticsEligibleProvider),
        isTrue);
    expect(
        _containerFor(_signedInAs('nasabah')).read(analyticsEligibleProvider),
        isFalse);
    expect(_containerFor(_signedInAs(null)).read(analyticsEligibleProvider),
        isFalse);
  });

  test('nobody signed in is not recorded, and signing out ends eligibility',
      () {
    final auth =
        TestAuthenticationNotifier(initialState: _signedInAs('pengelola'));
    final container = ProviderContainer(
        overrides: [authenticationProvider.overrideWith(() => auth)]);
    addTearDown(container.dispose);
    expect(container.read(analyticsEligibleProvider), isTrue);

    auth.setStateForTest(Unauthenticated());

    expect(container.read(analyticsEligibleProvider), isFalse);
  });
}
