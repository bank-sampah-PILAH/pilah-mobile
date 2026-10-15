import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/login_with_reviewer_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/reviewer_login_panel.dart';

class _MockAuthBloc extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

class _FakeAuthEvent extends Fake implements AuthenticationEvent {}

void main() {
  late _MockAuthBloc auth;

  setUpAll(() => registerFallbackValue(_FakeAuthEvent()));

  setUp(() {
    auth = _MockAuthBloc();
    whenListen(
      auth,
      const Stream<AuthenticationStates>.empty(),
      initialState: AuthenticationInitial(),
    );
  });

  tearDown(() async => auth.close());

  Future<void> pumpPanel(
    WidgetTester tester, {
    required Future<bool> Function() loadEnabled,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthenticationBloc>.value(
          value: auth,
          child: Scaffold(
            body: ReviewerLoginPanel(
              loadReviewerLoginEnabled: loadEnabled,
              isReleaseModeOverride: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'shows accessible credentials only when runtime config enables it',
    (tester) async {
      await pumpPanel(tester, loadEnabled: () async => true);

      expect(find.bySemanticsLabel('Email'), findsOneWidget);
      expect(find.bySemanticsLabel('Kata sandi'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).last).obscureText,
        isTrue,
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        ' reviewer@test.id ',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'secret password',
      );
      await tester.tap(find.text('Masuk dengan akun peninjau'));
      await tester.pump();

      final event = verify(() => auth.add(captureAny())).captured.single
          as LoginWithReviewerRequested;
      expect(event.email, 'reviewer@test.id');
      expect(event.password, 'secret password');
    },
  );

  testWidgets('hides the form after config failure and offers a retry', (
    tester,
  ) async {
    var calls = 0;
    await pumpPanel(
      tester,
      loadEnabled: () async {
        calls++;
        if (calls == 1) throw Exception('private config detail');
        return true;
      },
    );

    expect(find.bySemanticsLabel('Email'), findsNothing);
    expect(find.text('private config detail'), findsNothing);
    expect(find.text('Coba muat ulang'), findsOneWidget);

    await tester.tap(find.text('Coba muat ulang'));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.bySemanticsLabel('Email'), findsOneWidget);
  });

  testWidgets('hides the form when runtime config disables reviewer access', (
    tester,
  ) async {
    await pumpPanel(tester, loadEnabled: () async => false);

    expect(find.bySemanticsLabel('Email'), findsNothing);
    expect(find.text('Coba muat ulang'), findsNothing);
  });

  testWidgets('refreshes reviewer access whenever the app resumes', (
    tester,
  ) async {
    var calls = 0;
    var enabled = true;
    await pumpPanel(
      tester,
      loadEnabled: () async {
        calls++;
        return enabled;
      },
    );
    expect(find.bySemanticsLabel('Email'), findsOneWidget);
    expect(calls, 1);

    enabled = false;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.bySemanticsLabel('Email'), findsNothing);

    enabled = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(calls, 3);
    expect(find.bySemanticsLabel('Email'), findsOneWidget);
  });
}
