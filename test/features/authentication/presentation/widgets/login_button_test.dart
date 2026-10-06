import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart'
    as google_sign_in;
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/login_with_google_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/google_sign_in_error.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/login_button.dart';

class _MockAuthBloc extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

class _FakeAuthEvent extends Fake implements AuthenticationEvent {}

class _FakeAuthenticateParameters extends Fake
    implements google_sign_in.AuthenticateParameters {}

class _MockGoogleSignInPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements google_sign_in.GoogleSignInPlatform {}

void main() {
  late _MockAuthBloc auth;
  late google_sign_in.GoogleSignInPlatform originalGoogleSignInPlatform;
  late _MockGoogleSignInPlatform googleSignInPlatform;

  setUpAll(() {
    registerFallbackValue(_FakeAuthEvent());
    registerFallbackValue(_FakeAuthenticateParameters());
  });

  setUp(() {
    originalGoogleSignInPlatform = google_sign_in.GoogleSignInPlatform.instance;
    googleSignInPlatform = _MockGoogleSignInPlatform();
    google_sign_in.GoogleSignInPlatform.instance = googleSignInPlatform;
    auth = _MockAuthBloc();
    whenListen(
      auth,
      const Stream<AuthenticationStates>.empty(),
      initialState: AuthenticationInitial(),
    );
  });

  tearDown(() async {
    google_sign_in.GoogleSignInPlatform.instance = originalGoogleSignInPlatform;
    await auth.close();
  });

  testWidgets('submits the authenticated Google user to the bloc',
      (tester) async {
    when(() => googleSignInPlatform.authenticate(any())).thenAnswer(
      (_) async => const google_sign_in.AuthenticationResults(
        user: google_sign_in.GoogleSignInUserData(
          email: 'ayu@example.com',
          id: 'google-user-id',
        ),
        authenticationTokens:
            google_sign_in.AuthenticationTokenData(idToken: 'signed-id-token'),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthenticationBloc>.value(
          value: auth,
          child: const Scaffold(body: LoginButton()),
        ),
      ),
    );
    await tester.tap(find.text('Masuk dengan Google'));
    await tester.pumpAndSettle();

    final event = verify(() => auth.add(captureAny())).captured.single
        as LoginWithGoogleRequested;
    expect(event.name, 'Unknown');
    expect(event.email, 'ayu@example.com');
    expect(event.photoUrl, '');
    expect(event.idToken, 'signed-id-token');
  });

  testWidgets('shows a safe error for a failed Google sign-in', (tester) async {
    when(() => googleSignInPlatform.authenticate(any())).thenThrow(
      const GoogleSignInException(
        code: GoogleSignInExceptionCode.clientConfigurationError,
        description: 'private OAuth configuration detail',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthenticationBloc>.value(
          value: auth,
          child: const Scaffold(body: LoginButton()),
        ),
      ),
    );
    await tester.tap(find.text('Masuk dengan Google'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text(googleSignInFallbackMessage), findsOneWidget);
    expect(find.text('private OAuth configuration detail'), findsNothing);
  });

  testWidgets('silently ignores a cancelled Google sign-in', (tester) async {
    when(() => googleSignInPlatform.authenticate(any())).thenThrow(
      const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthenticationBloc>.value(
          value: auth,
          child: const Scaffold(body: LoginButton()),
        ),
      ),
    );
    await tester.tap(find.text('Masuk dengan Google'));
    await tester.pumpAndSettle();

    expect(find.text(googleSignInFallbackMessage), findsNothing);
    verifyNever(() => auth.add(any()));
  });

  testWidgets('uses the platform web button adapter when requested',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LoginButton(isWebOverride: true),
        ),
      ),
    );

    expect(tester.takeException(), isA<UnsupportedError>());
  }, skip: kIsWeb);
}
