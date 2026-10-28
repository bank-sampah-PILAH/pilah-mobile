import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';

import '../../../../support/auth_support.dart';

void main() {
  late TestAuthenticationNotifier auth;

  setUp(() => auth = TestAuthenticationNotifier());

  testWidgets('shows the demo login action when enabled', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProviderScope(
          overrides: [authenticationProvider.overrideWith(() => auth)],
          child: const LoginPage(debugShowDemoLogin: true),
        ),
      ),
    );

    expect(find.text('Masuk dengan akun demo'), findsOneWidget);
    final googleButton = find.ancestor(
      of: find.text('Masuk dengan Google'),
      matching: find.byType(OutlinedButton),
    );
    final demoButton = find.ancestor(
      of: find.text('Masuk dengan akun demo'),
      matching: find.byType(OutlinedButton),
    );
    expect(
        tester.getSize(demoButton).width, tester.getSize(googleButton).width);
  });

  testWidgets('does not show the demo login action when disabled',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProviderScope(
          overrides: [authenticationProvider.overrideWith(() => auth)],
          child: const LoginPage(debugShowDemoLogin: false),
        ),
      ),
    );

    expect(find.text('Masuk dengan akun demo'), findsNothing);
  });

  testWidgets('uses the desktop layout and shows demo login when enabled',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 960);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: ProviderScope(
          overrides: [authenticationProvider.overrideWith(() => auth)],
          child: const LoginPage(debugShowDemoLogin: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final desktopContent = find.byKey(const ValueKey('desktop-login-content'));
    expect(find.text('Masuk ke akun Anda'), findsOneWidget);
    expect(find.text('Masuk dengan akun demo'), findsOneWidget);
    expect(tester.getSize(desktopContent).width, 1120);
    expect(find.text('Selamat datang kembali'), findsNothing);
    expect(tester.getSize(find.byType(SvgPicture)).height, 160,
        reason: 'the brand fills the left column on its own');
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the existing layout on narrow screens', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: ProviderScope(
          overrides: [authenticationProvider.overrideWith(() => auth)],
          child: const LoginPage(debugShowDemoLogin: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Masuk ke akun Anda'), findsNothing);
    expect(find.text('Selamat datang kembali'), findsNothing,
        reason: 'the phone goes straight to the sign-in buttons');
  });

  testWidgets('on a phone every sign-in button is visible without scrolling',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(411, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: ProviderScope(
          overrides: [authenticationProvider.overrideWith(() => auth)],
          child: const LoginPage(debugShowDemoLogin: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Masuk dengan Email'), findsOneWidget);
    expect(tester.getRect(find.text('Masuk dengan Email')).bottom,
        lessThanOrEqualTo(800));
  });
}
