import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/demo_login_button.dart';

import '../../../../support/auth_support.dart';

void main() {
  late TestAuthenticationNotifier auth;

  setUp(() => auth = TestAuthenticationNotifier());

  Future<void> pumpButton(WidgetTester tester) => tester.pumpWidget(
        ProviderScope(
          overrides: [authenticationProvider.overrideWith(() => auth)],
          child: const MaterialApp(
            home: Scaffold(body: DemoLoginButton()),
          ),
        ),
      );

  testWidgets('signs in with the Pengurus Induk role token', (tester) async {
    await pumpButton(tester);

    await tester.tap(find.text('Masuk dengan akun demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pengelola Induk'));
    await tester.pump();

    expect(auth.lastIdToken,
        'dev-pengelola-induk:induk.demo@example.com:Pengelola Induk PILAH E2E');
  });

  testWidgets('dispatches the selected seeded account token', (tester) async {
    await pumpButton(tester);

    await tester.tap(find.text('Masuk dengan akun demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nasabah'));
    await tester.pump();

    expect(auth.lastIdToken,
        'dev-nasabah:nasabah.demo@example.com:Nasabah PILAH E2E');
  });
}
