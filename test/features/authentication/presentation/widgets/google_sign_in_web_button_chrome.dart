import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/google_sign_in_web_button.dart';

class _MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

void main() {
  testWidgets('forwards sign-in and stream errors', (tester) async {
    final events =
        StreamController<GoogleSignInAuthenticationEvent>.broadcast();
    final user = _MockGoogleSignInAccount();
    GoogleSignInAccount? authenticated;
    Object? streamError;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildWebGoogleSignInButton(
            isLoading: false,
            authenticationEvents: events.stream,
            onAuthenticated: (value) => authenticated = value,
            onError: (error) => streamError = error,
            buttonBuilder: () => const Text('Google button'),
          ),
        ),
      ),
    );

    expect(find.text('Google button'), findsOneWidget);
    events.add(GoogleSignInAuthenticationEventSignOut());
    events.add(GoogleSignInAuthenticationEventSignIn(user: user));
    await tester.pump();
    expect(authenticated, same(user));

    final error = StateError('stream failed');
    events.addError(error);
    await tester.pump();
    expect(streamError, same(error));

    await tester.pumpWidget(const SizedBox.shrink());
    await events.close();
  });

  testWidgets('shows loading instead of rendering the Google button',
      (tester) async {
    final events =
        StreamController<GoogleSignInAuthenticationEvent>.broadcast();
    var renderedButton = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildWebGoogleSignInButton(
            isLoading: true,
            authenticationEvents: events.stream,
            onAuthenticated: (_) {},
            onError: (_) {},
            buttonBuilder: () {
              renderedButton = true;
              return const Text('Google button');
            },
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(renderedButton, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await events.close();
  });
}
