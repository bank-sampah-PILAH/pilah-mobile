import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';

import '../../../../support/auth_support.dart';

void main() {
  // Authentication states are value objects, so equality follows their payload.
  test('payload-free states are equal to each other', () {
    expect(Unauthenticated(), Unauthenticated());
    expect(AuthenticationLoading(), AuthenticationLoading());
    expect(AuthenticationInitial(), AuthenticationInitial());
  });

  test('payload states compare by payload', () {
    final auth = testAuth();
    expect(Authenticated(authEntity: auth), Authenticated(authEntity: auth));
  });
}
