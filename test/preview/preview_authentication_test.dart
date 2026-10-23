import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/preview/preview_authentication.dart';

void main() {
  test('preview restores, refreshes and logs out the offline session',
      () async {
    final container = ProviderContainer(
      overrides: [
        authenticationProvider
            .overrideWith(createPreviewAuthenticationNotifier),
      ],
    );
    addTearDown(container.dispose);
    final states = <AuthenticationStates>[];
    final subscription = container.listen(authenticationProvider, (_, next) {
      states.add(next);
    });
    addTearDown(subscription.close);

    expect(container.read(authenticationProvider), isA<Authenticated>());
    expect((container.read(authenticationProvider) as Authenticated).authEntity,
        PreviewAuthenticationSession.auth);

    await container.read(authenticationProvider.notifier).refreshUser();
    await container.read(authenticationProvider.notifier).logout();
    expect(container.read(authenticationProvider), isA<Unauthenticated>());

    await container.read(authenticationProvider.notifier).checkSession();
    expect(container.read(authenticationProvider), isA<Unauthenticated>());
    expect(states, contains(isA<Unauthenticated>()));
  });
}
