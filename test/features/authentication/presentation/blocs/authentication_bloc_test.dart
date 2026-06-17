import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/domain/use_cases/authentication_use_cases.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/login_refresh_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/post_login_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/states/post_login_states.dart';

class MockAuthenticationUseCases extends Mock implements AuthenticationUseCases {}

void main() {
  late AuthenticationBloc bloc;
  late MockAuthenticationUseCases mockUseCases;

  setUp(() {
    mockUseCases = MockAuthenticationUseCases();
    bloc = AuthenticationBloc(mockUseCases);
  });

  tearDown(() {
    bloc.close();
  });

  group('AuthenticationBloc', () {
    const tUsername = 'test_user';
    const tPassword = 'password123';
    final tAuth = Auth(
      id: 1,
      username: tUsername,
      email: 'test@example.com',
      firstName: 'Test',
      lastName: 'User',
      gender: 'male',
      image: '',
      token: 'access_token',
    );

    test('initial state should be PostLoginInitState', () {
      expect(bloc.state, isA<PostLoginInitState>());
    });

    blocTest<AuthenticationBloc, dynamic>(
      'emits [Loading, Success] when login is successful',
      build: () {
        when(() => mockUseCases.postLogin(tUsername, tPassword))
            .thenAnswer((_) async => Right(tAuth));
        when(() => mockUseCases.saveToken(tAuth.token, tAuth.token))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const PostLoginEvent(
        username: tUsername,
        password: tPassword,
      )),
      expect: () => [
        isA<PostLoginLoadingState>(),
        isA<PostLoginSuccessState>(),
      ],
      verify: (_) {
        verify(() => mockUseCases.postLogin(tUsername, tPassword)).called(1);
        verify(() => mockUseCases.saveToken(tAuth.token, tAuth.token)).called(1);
      },
    );

    blocTest<AuthenticationBloc, dynamic>(
      'emits [Loading, Error] when login fails',
      build: () {
        when(() => mockUseCases.postLogin(tUsername, tPassword))
            .thenAnswer((_) async => Left(GeneralException(message: 'Login failed')));
        return bloc;
      },
      act: (bloc) => bloc.add(const PostLoginEvent(
        username: tUsername,
        password: tPassword,
      )),
      expect: () => [
        isA<PostLoginLoadingState>(),
        isA<PostLoginErrorState>(),
      ],
      verify: (_) {
        verify(() => mockUseCases.postLogin(tUsername, tPassword)).called(1);
        verifyNever(() => mockUseCases.saveToken(any(), any()));
      },
    );

    blocTest<AuthenticationBloc, dynamic>(
      'emits [InitState] when LoginRefreshEvent is added and state is Error',
      build: () => bloc,
      seed: () => PostLoginErrorState(message: 'Error'),
      act: (bloc) => bloc.add(LoginRefreshEvent()),
      expect: () => [
        isA<PostLoginInitState>(),
      ],
    );
  });
}
