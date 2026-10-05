import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart'
    as google_sign_in;
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/login_with_google_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/role_selection_page.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/google_sign_in_error.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/pump_app.dart';

class _MockGoogleSignInPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements google_sign_in.GoogleSignInPlatform {}

void main() {
  late MockAuthBloc auth;
  late StreamController<AuthenticationStates> states;
  late google_sign_in.GoogleSignInPlatform originalPlatform;
  late _MockGoogleSignInPlatform platform;

  setUpAll(() {
    registerFallbackValue(const google_sign_in.AuthenticateParameters());
    registerFallbackValue(LoginWithGoogleRequested(
        name: 'x', email: 'x', photoUrl: 'x', idToken: 'x'));
  });

  setUp(() {
    di.registerSingleton<InviteTokenStore>(InviteTokenStore());
    originalPlatform = google_sign_in.GoogleSignInPlatform.instance;
    platform = _MockGoogleSignInPlatform();
    google_sign_in.GoogleSignInPlatform.instance = platform;
    states = StreamController<AuthenticationStates>.broadcast();
    auth = MockAuthBloc();
    whenListen(auth, states.stream, initialState: AuthenticationInitial());
  });

  tearDown(() async {
    google_sign_in.GoogleSignInPlatform.instance = originalPlatform;
    await di.unregister<InviteTokenStore>();
    unawaited(states.close());
  });

  Future<void> pumpPage(WidgetTester tester) => pumpRouted(
        tester,
        const LoginPage(debugShowDemoLogin: false),
        extraRoutes: ['/dashboard', RoleSelectionPage.route],
        wrap: (app) =>
            BlocProvider<AuthenticationBloc>.value(value: auth, child: app),
      );

  Future<void> tapGoogle(WidgetTester tester) async {
    await tester.tap(find.text('Masuk dengan Google'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  group('Google button', () {
    testWidgets('hands the chosen account and ID token to the auth bloc',
        (tester) async {
      when(() => platform.authenticate(any()))
          .thenAnswer((_) async => const google_sign_in.AuthenticationResults(
                user: google_sign_in.GoogleSignInUserData(
                  email: 'ayu@example.com',
                  id: 'g1',
                  displayName: 'Ayu',
                  photoUrl: 'https://example.com/a.png',
                ),
                authenticationTokens:
                    google_sign_in.AuthenticationTokenData(idToken: 'id-token'),
              ));
      await pumpPage(tester);

      await tapGoogle(tester);

      final event = verify(() => auth.add(captureAny())).captured.single
          as LoginWithGoogleRequested;
      expect(event.name, 'Ayu');
      expect(event.email, 'ayu@example.com');
      expect(event.photoUrl, 'https://example.com/a.png');
      expect(event.idToken, 'id-token');
    });

    testWidgets('fills in safe defaults for a sparse Google account',
        (tester) async {
      when(() => platform.authenticate(any()))
          .thenAnswer((_) async => const google_sign_in.AuthenticationResults(
                user: google_sign_in.GoogleSignInUserData(
                    email: 'ayu@example.com', id: 'g1'),
                authenticationTokens:
                    google_sign_in.AuthenticationTokenData(idToken: null),
              ));
      await pumpPage(tester);

      await tapGoogle(tester);

      final event = verify(() => auth.add(captureAny())).captured.single
          as LoginWithGoogleRequested;
      expect(event.name, 'Unknown');
      expect(event.photoUrl, '');
      expect(event.idToken, '');
    });

    testWidgets('a cancelled account picker aborts silently', (tester) async {
      when(() => platform.authenticate(any())).thenThrow(
          const GoogleSignInException(
              code: GoogleSignInExceptionCode.canceled));
      await pumpPage(tester);

      await tapGoogle(tester);
      await tester.pump(const Duration(seconds: 1));

      verifyNever(() => auth.add(any()));
      expect(find.text('Login Gagal'), findsNothing);
    });

    testWidgets('any other failure shows the clean fallback message',
        (tester) async {
      when(() => platform.authenticate(any())).thenThrow(
          const GoogleSignInException(
              code: GoogleSignInExceptionCode.unknownError,
              description: 'secret client id 123'));
      await pumpPage(tester);

      await tapGoogle(tester);
      await pumpToast(tester);

      verifyNever(() => auth.add(any()));
      expect(find.text('Login Gagal'), findsOneWidget);
      expect(find.text(googleSignInFallbackMessage), findsOneWidget);
      expect(find.textContaining('secret'), findsNothing);
      await settleToasts(tester);
    });
  });

  group('auth state changes', () {
    testWidgets('a signed-in user is sent to the dashboard', (tester) async {
      await pumpPage(tester);

      states.add(Authenticated(authEntity: testAuth(role: 'nasabah')));
      await tester.pumpAndSettle();

      expect(find.text('route:/dashboard'), findsOneWidget);
    });

    testWidgets('an unknown Google account is sent to role selection',
        (tester) async {
      await pumpPage(tester);

      states.add(GoogleRegistrationPending(
          registration: GoogleRegistrationRequired(
        registrationToken: 't',
        expiresIn: 600,
        name: 'Ayu',
        email: 'ayu@example.com',
        photoUrl: '',
      )));
      await tester.pumpAndSettle();

      expect(find.text('route:${RoleSelectionPage.route}'), findsOneWidget);
    });

    testWidgets(
        'a failed login is reported and the spinner replaces the button',
        (tester) async {
      await pumpPage(tester);

      states.add(AuthenticationLoading());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Masuk dengan Google'), findsNothing);

      states.add(AuthenticationFailure(message: 'Akun ditolak'));
      await pumpToast(tester);

      expect(find.text('Akun ditolak'), findsOneWidget);
      await settleToasts(tester);
    });
  });
}
