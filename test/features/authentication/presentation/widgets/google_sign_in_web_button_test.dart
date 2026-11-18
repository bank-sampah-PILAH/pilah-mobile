import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/google_sign_in_web_button.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/google_sign_in_web_renderer_stub.dart';

import 'google_sign_in_web_button_chrome.dart' as browser_tests;

void main() {
  browser_tests.main();

  testWidgets('uses the Indonesian outline button configuration',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildWebGoogleSignInButton(
            isLoading: false,
            onAuthenticated: (_) {},
            onError: (_) {},
          ),
        ),
      ),
    );

    final renderer = tester.widget<GoogleSignInWebRendererStub>(
      find.byType(GoogleSignInWebRendererStub),
    );
    expect(renderer.configuration?.theme, GSIButtonTheme.outline);
    expect(renderer.configuration?.size, GSIButtonSize.large);
    expect(renderer.configuration?.text, GSIButtonText.signinWith);
    expect(renderer.configuration?.locale, 'id');
    expect(find.byKey(const ValueKey('google-sign-in-web-renderer-stub')),
        findsOneWidget);
  });
}
