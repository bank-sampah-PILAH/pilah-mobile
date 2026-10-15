import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart'
    as google_sign_in;
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/register_google_role_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/role_selection_page.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/pump_app.dart';

class _MockGoogleSignInPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements google_sign_in.GoogleSignInPlatform {}

void main() {
  final registration = GoogleRegistrationRequired(
    registrationToken: 'signed-token',
    expiresIn: 600,
    name: 'Ayu Lestari',
    email: 'ayu@example.com',
    photoUrl: '',
  );

  late MockAuthBloc auth;
  late StreamController<AuthenticationStates> states;
  late google_sign_in.GoogleSignInPlatform originalPlatform;
  late _MockGoogleSignInPlatform googleSignIn;

  setUpAll(() => registerFallbackValue(const ChangeGoogleAccountRequested()));

  setUp(() {
    di.registerSingleton<InviteTokenStore>(InviteTokenStore());
    originalPlatform = google_sign_in.GoogleSignInPlatform.instance;
    googleSignIn = _MockGoogleSignInPlatform();
    google_sign_in.GoogleSignInPlatform.instance = googleSignIn;
    states = StreamController<AuthenticationStates>.broadcast();
    auth = MockAuthBloc();
    whenListen(auth, states.stream,
        initialState: GoogleRegistrationPending(registration: registration));
  });

  tearDown(() async {
    google_sign_in.GoogleSignInPlatform.instance = originalPlatform;
    await di.unregister<InviteTokenStore>();
    unawaited(states.close());
  });

  Future<void> pumpPage(WidgetTester tester) => pumpRouted(
        tester,
        const RoleSelectionPage(),
        extraRoutes: ['/dashboard', LoginPage.route],
        wrap: (app) =>
            BlocProvider<AuthenticationBloc>.value(value: auth, child: app),
      );

  testWidgets('goes to the dashboard once registration authenticates',
      (tester) async {
    await pumpPage(tester);

    states.add(Authenticated(authEntity: testAuth(role: 'nasabah')));
    await tester.pumpAndSettle();

    expect(find.text('route:/dashboard'), findsOneWidget);
  });

  testWidgets('shows the registration failure and stays on the page',
      (tester) async {
    await pumpPage(tester);

    states.add(GoogleRegistrationFailure(
        registration: registration, message: 'Peran tidak valid'));
    await pumpToast(tester);

    expect(find.text('Pendaftaran Gagal'), findsOneWidget);
    expect(find.text('Peran tidak valid'), findsOneWidget);
    expect(find.text('Daftar Akun'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('an expired registration returns to login with a notice',
      (tester) async {
    await pumpPage(tester);

    states.add(GoogleRegistrationExpired(message: 'Sesi pendaftaran habis'));
    await pumpToast(tester);

    expect(find.text('route:${LoginPage.route}'), findsOneWidget);
    expect(find.text('Sesi Berakhir'), findsOneWidget);
    expect(find.text('Sesi pendaftaran habis'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('reports a failed Google sign-out and lets the user try again',
      (tester) async {
    when(() => googleSignIn.signOut(const google_sign_in.SignOutParams()))
        .thenThrow(Exception('offline'));
    await pumpPage(tester);

    await tester.tap(find.text('Ganti akun'));
    await pumpToast(tester);

    expect(find.text('Ganti Akun Gagal'), findsOneWidget);
    expect(find.text('Daftar Akun'), findsOneWidget);
    verifyNever(() => auth.add(any()));

    await settleToasts(tester);
    when(() => googleSignIn.signOut(const google_sign_in.SignOutParams()))
        .thenAnswer((_) async {});
    await tester.tap(find.text('Ganti akun'));
    await tester.pumpAndSettle();
    expect(find.text('route:${LoginPage.route}'), findsOneWidget);
    verify(() => auth.add(any())).called(1);
  });
}
