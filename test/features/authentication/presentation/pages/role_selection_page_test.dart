import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart'
    as google_sign_in;
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';

import '../../../../support/auth_support.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/role_selection_page.dart';

class _MockGoogleSignInPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements google_sign_in.GoogleSignInPlatform {}

void main() {
  late TestAuthenticationNotifier auth;
  late google_sign_in.GoogleSignInPlatform originalPlatform;
  late _MockGoogleSignInPlatform googleSignInPlatform;
  final registration = GoogleRegistrationRequired(
    registrationToken: 'signed-token',
    expiresIn: 600,
    name: 'Ayu Lestari',
    email: 'ayu@example.com',
    photoUrl: 'https://example.com/ayu.png',
  );

  setUp(() {
    originalPlatform = google_sign_in.GoogleSignInPlatform.instance;
    googleSignInPlatform = _MockGoogleSignInPlatform();
    google_sign_in.GoogleSignInPlatform.instance = googleSignInPlatform;
    when(() =>
            googleSignInPlatform.signOut(const google_sign_in.SignOutParams()))
        .thenAnswer((_) async {});
    auth = TestAuthenticationNotifier(
      initialState: GoogleRegistrationPending(registration: registration),
    );
  });

  tearDown(() {
    google_sign_in.GoogleSignInPlatform.instance = originalPlatform;
  });

  testWidgets('offers roles supported by the platform and submits selection',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [authenticationProvider.overrideWith(() => auth)],
      child: const MaterialApp(home: RoleSelectionPage()),
    ));

    expect(find.text('Daftar Akun'), findsOneWidget);
    expect(find.text('Langkah 1'), findsOneWidget);
    expect(find.text('ayu@example.com'), findsOneWidget);
    expect(find.text('Nasabah'), kIsWeb ? findsNothing : findsOneWidget);
    expect(find.text('Pengurus Bank Sampah'), findsOneWidget);
    expect(find.text('Pengelola Bank Sampah Induk'), findsOneWidget);
    expect(find.text('Superadmin'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text(kIsWeb ? 'Pengelola Bank Sampah' : 'Nasabah'));
    await tester.pump();
    await tester.tap(find.text('Lanjutkan'));

    expect(
      auth.lastRole,
      kIsWeb
          ? GoogleRegistrationRole.pengelola
          : GoogleRegistrationRole.nasabah,
    );
  });

  testWidgets('signs out of Google before changing accounts', (tester) async {
    final router = GoRouter(
      initialLocation: RoleSelectionPage.route,
      routes: [
        GoRoute(
          path: RoleSelectionPage.route,
          builder: (context, state) => ProviderScope(
            overrides: [authenticationProvider.overrideWith(() => auth)],
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

    expect(find.text('Login page'), findsOneWidget);
    expect(auth.calls, contains('changeGoogleAccount'));
    verify(() =>
            googleSignInPlatform.signOut(const google_sign_in.SignOutParams()))
        .called(1);
  });
}
