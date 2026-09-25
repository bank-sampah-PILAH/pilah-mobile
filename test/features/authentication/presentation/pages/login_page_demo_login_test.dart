import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';

class _MockAuthBloc extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

void main() {
  late _MockAuthBloc auth;

  setUp(() {
    auth = _MockAuthBloc();
    whenListen(
      auth,
      const Stream<AuthenticationStates>.empty(),
      initialState: AuthenticationInitial(),
    );
  });

  tearDown(() async {
    await auth.close();
  });

  testWidgets('shows the demo login action when enabled', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthenticationBloc>.value(
          value: auth,
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
        home: BlocProvider<AuthenticationBloc>.value(
          value: auth,
          child: const LoginPage(debugShowDemoLogin: false),
        ),
      ),
    );

    expect(find.text('Masuk dengan akun demo'), findsNothing);
  });
}
