import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart'
    as google_sign_in;
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/register_google_role_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/role_selection_page.dart';

class _MockAuthBloc extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

class _FakeAuthEvent extends Fake implements AuthenticationEvent {}

class _MockGoogleSignInPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements google_sign_in.GoogleSignInPlatform {}

void main() {
  late _MockAuthBloc auth;
  late google_sign_in.GoogleSignInPlatform originalGoogleSignInPlatform;
  late _MockGoogleSignInPlatform googleSignInPlatform;
  final registration = GoogleRegistrationRequired(
    registrationToken: 'signed-token',
    expiresIn: 600,
    name: 'Ayu Lestari',
    email: 'ayu@example.com',
    photoUrl: 'https://example.com/ayu.png',
  );

  setUpAll(() => registerFallbackValue(_FakeAuthEvent()));

  setUp(() {
    originalGoogleSignInPlatform = google_sign_in.GoogleSignInPlatform.instance;
    googleSignInPlatform = _MockGoogleSignInPlatform();
    google_sign_in.GoogleSignInPlatform.instance = googleSignInPlatform;
    when(() =>
            googleSignInPlatform.signOut(const google_sign_in.SignOutParams()))
        .thenAnswer((_) async {});
    auth = _MockAuthBloc();
    whenListen(
      auth,
      const Stream<AuthenticationStates>.empty(),
      initialState: GoogleRegistrationPending(registration: registration),
    );
  });

  tearDown(() async {
    google_sign_in.GoogleSignInPlatform.instance = originalGoogleSignInPlatform;
    await auth.close();
  });

  testWidgets('offers three non-Superadmin roles and submits the selection',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthenticationBloc>.value(
          value: auth,
          child: const RoleSelectionPage(),
        ),
      ),
    );

    expect(find.text('Daftar Akun'), findsOneWidget);
    expect(find.text('Langkah 1'), findsOneWidget);
    expect(find.text('ayu@example.com'), findsOneWidget);
    expect(find.text('Nasabah'), findsOneWidget);
    expect(find.text('Pengelola Bank Sampah'), findsOneWidget);
    expect(find.text('Pengelola Bank Sampah Induk'), findsOneWidget);
    expect(find.text('Superadmin'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Nasabah'));
    await tester.pump();
    await tester.tap(find.text('Lanjutkan'));

    final event = verify(() => auth.add(captureAny())).captured.single
        as RegisterGoogleRoleRequested;
    expect(event.role, GoogleRegistrationRole.nasabah);
  });

  testWidgets('signs out of Google before changing accounts', (tester) async {
    final router = GoRouter(
      initialLocation: RoleSelectionPage.route,
      routes: [
        GoRoute(
          path: RoleSelectionPage.route,
          builder: (context, state) => BlocProvider<AuthenticationBloc>.value(
            value: auth,
            child: const RoleSelectionPage(),
          ),
        ),
        GoRoute(
          path: LoginPage.route,
          builder: (context, state) => const Text('Login page'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Ganti akun'));
    await tester.pumpAndSettle();

    verify(() =>
            googleSignInPlatform.signOut(const google_sign_in.SignOutParams()))
        .called(1);
    expect(find.text('Login page'), findsOneWidget);
    expect(
      verify(() => auth.add(captureAny())).captured.single,
      isA<ChangeGoogleAccountRequested>(),
    );
  });
}
