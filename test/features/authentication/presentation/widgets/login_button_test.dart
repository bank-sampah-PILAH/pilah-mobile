import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart'
    as google_sign_in;
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/google_sign_in_error.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/login_button.dart';

import '../../../../support/auth_support.dart';

class _FakeAuthenticateParameters extends Fake
    implements google_sign_in.AuthenticateParameters {}

class _MockGoogleSignInPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements google_sign_in.GoogleSignInPlatform {}

class _MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

void main() {
  late TestAuthenticationNotifier auth;
  late google_sign_in.GoogleSignInPlatform originalGoogleSignInPlatform;
  late _MockGoogleSignInPlatform googleSignInPlatform;

  setUpAll(() {
    registerFallbackValue(_FakeAuthenticateParameters());
  });

  setUp(() {
    originalGoogleSignInPlatform = google_sign_in.GoogleSignInPlatform.instance;
    googleSignInPlatform = _MockGoogleSignInPlatform();
    google_sign_in.GoogleSignInPlatform.instance = googleSignInPlatform;
    auth = TestAuthenticationNotifier();
  });

  tearDown(() async {
    google_sign_in.GoogleSignInPlatform.instance = originalGoogleSignInPlatform;
  });

  Future<void> pumpLoginButton(WidgetTester tester, Widget button) =>
      tester.pumpWidget(
        ProviderScope(
          overrides: [authenticationProvider.overrideWith(() => auth)],
          child: MaterialApp(home: Scaffold(body: button)),
        ),
      );

  testWidgets('submits the Google ID token to the auth provider',
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

    await pumpLoginButton(tester, const LoginButton());
    await tester.tap(find.text('Masuk dengan Google'));
    await tester.pumpAndSettle();

    expect(auth.lastIdToken, 'signed-id-token');
    expect(auth.calls, contains('loginWithGoogle'));
  });

  testWidgets('shows a safe error for a failed Google sign-in', (tester) async {
    when(() => googleSignInPlatform.authenticate(any())).thenThrow(
      const GoogleSignInException(
        code: GoogleSignInExceptionCode.clientConfigurationError,
        description: 'private OAuth configuration detail',
      ),
    );

    await pumpLoginButton(tester, const LoginButton());
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

    await pumpLoginButton(tester, const LoginButton());
    await tester.tap(find.text('Masuk dengan Google'));
    await tester.pumpAndSettle();

    expect(find.text(googleSignInFallbackMessage), findsNothing);
    expect(auth.calls, isEmpty);
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

  testWidgets('routes web sign-in and error callbacks through the login button',
      (tester) async {
    final user = _MockGoogleSignInAccount();
    when(() => user.authentication)
        .thenReturn(const GoogleSignInAuthentication(idToken: 'web-id-token'));
    when(() => user.displayName).thenReturn('Ayu Lestari');
    when(() => user.email).thenReturn('ayu@example.com');
    when(() => user.photoUrl).thenReturn('https://example.com/ayu.png');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authenticationProvider.overrideWith(() => auth)],
        child: MaterialApp(
          home: Scaffold(
            body: LoginButton(
              isWebOverride: true,
              webButtonBuilderOverride: ({
                required bool isLoading,
                required ValueChanged<GoogleSignInAccount> onAuthenticated,
                required ValueChanged<Object> onError,
              }) =>
                  Column(
                children: [
                  TextButton(
                    onPressed: () => onAuthenticated(user),
                    child: const Text('simulate web sign-in'),
                  ),
                  TextButton(
                    onPressed: () => onError(Exception('private OAuth detail')),
                    child: const Text('simulate web error'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('simulate web sign-in'));
    await tester.pump();
    expect(auth.lastIdToken, 'web-id-token');
    expect(auth.calls, contains('loginWithGoogle'));

    await tester.tap(find.text('simulate web error'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text(googleSignInFallbackMessage), findsOneWidget);
    expect(find.text('private OAuth detail'), findsNothing);
  });
}
