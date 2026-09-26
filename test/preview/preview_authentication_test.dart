import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/check_session_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/logout_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/refresh_user_events.dart';
import 'package:pilah_mobile/preview/preview_authentication.dart';

void main() {
  test('preview handles restore, refresh and logout using real bloc events',
      () async {
    final bloc = createPreviewAuthenticationBloc();
    addTearDown(bloc.close);
    final restored = await bloc.stream.firstWhere((s) => s is Authenticated);
    expect((restored as Authenticated).authEntity,
        PreviewAuthenticationSession.auth);

    bloc.add(RefreshUserRequested());
    // Refresh can retain the same state; logout must still be handled normally.
    final loggedOut = bloc.stream.firstWhere((s) => s is Unauthenticated);
    bloc.add(LogoutRequested());
    await loggedOut;
    final checked = bloc.stream.firstWhere((s) => s is Unauthenticated);
    bloc.add(CheckSessionRequested());
    await checked;
    expect(bloc.state, isA<Unauthenticated>());
  });
}
