import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/post_login_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/states/post_login_states.dart';

import '../../../../support/auth_support.dart';

void main() {
  // Bloc drops an emission equal to the current state, so the payload-free
  // states must compare equal and payload states must compare by payload.
  test('payload-free states are equal to each other', () {
    expect(Unauthenticated(), Unauthenticated());
    expect(AuthenticationLoading(), AuthenticationLoading());
    expect(AuthenticationInitial(), AuthenticationInitial());
    expect(PostLoginInitState(), PostLoginInitState());
    expect(PostLoginLoadingState(), PostLoginLoadingState());
  });

  test('payload states compare by payload', () {
    expect(
        PostLoginErrorState(message: 'a'), PostLoginErrorState(message: 'a'));
    expect(PostLoginErrorState(message: 'a'),
        isNot(PostLoginErrorState(message: 'b')));
    final auth = testAuth();
    expect(
        PostLoginSuccessState(auth: auth), PostLoginSuccessState(auth: auth));
    expect(Authenticated(authEntity: auth), Authenticated(authEntity: auth));
  });

  test('a login event carries the entered credentials', () {
    final event = PostLoginEvent(username: 'siti', password: 'rahasia');
    expect(event.username, 'siti');
    expect(event.password, 'rahasia');
  });
}
