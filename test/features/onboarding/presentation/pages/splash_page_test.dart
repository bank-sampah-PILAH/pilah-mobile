import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/check_session_events.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/splash_page.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/pump_app.dart';

class _FakeAuthEvent extends Fake implements AuthenticationEvent {}

void main() {
  late InviteTokenStore store;

  setUpAll(() => registerFallbackValue(_FakeAuthEvent()));

  setUp(() {
    store = InviteTokenStore();
    di.registerSingleton<InviteTokenStore>(store);
  });

  tearDown(() => di.unregister<InviteTokenStore>());

  Future<MockAuthBloc> open(
    WidgetTester tester, {
    required AuthenticationStates initial,
    List<AuthenticationStates> then = const [],
  }) async {
    final bloc = MockAuthBloc();
    whenListen(bloc, Stream<AuthenticationStates>.fromIterable(then),
        initialState: initial);
    await pumpRouted(
      tester,
      BlocProvider<AuthenticationBloc>.value(
        value: bloc,
        // A non-const instance so the constructor itself runs.
        // ignore: prefer_const_constructors
        child: SplashPage(),
      ),
      extraRoutes: ['/login', '/dashboard', '/pending-approval'],
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    return bloc;
  }

  testWidgets('asks the bloc to restore the session on start', (tester) async {
    final bloc = await open(tester, initial: AuthenticationInitial());

    verify(() => bloc.add(any(that: isA<CheckSessionRequested>()))).called(1);
    expect(find.text('PILAH'), findsOneWidget);
    expect(find.text('Sistem Manajemen Bank Sampah'), findsOneWidget);
  });

  testWidgets('a restored session goes to its onboarding destination',
      (tester) async {
    await open(tester, initial: AuthenticationInitial(), then: [
      Authenticated(authEntity: testAuth()),
    ]);

    expect(find.text('route:/dashboard'), findsOneWidget);
  });

  testWidgets('a pending bank sampah lands on the review screen',
      (tester) async {
    await open(tester, initial: AuthenticationInitial(), then: [
      Authenticated(
        authEntity: const AuthEntity(
          name: 'Siti',
          email: 's@x.test',
          photoUrl: '',
          token: 't',
          role: 'pengelola',
          nextStep: 'approval_pending',
        ),
      ),
    ]);

    expect(find.text('route:/pending-approval'), findsOneWidget);
  });

  testWidgets('no session goes to login', (tester) async {
    await open(tester,
        initial: AuthenticationInitial(), then: [Unauthenticated()]);

    expect(find.text('route:/login'), findsOneWidget);
  });

  testWidgets('a failed restore goes to login, and only routes once',
      (tester) async {
    await open(tester, initial: AuthenticationInitial(), then: [
      AuthenticationFailure(message: 'x'),
      Authenticated(authEntity: testAuth()),
    ]);

    expect(find.text('route:/login'), findsOneWidget);
  });
}
