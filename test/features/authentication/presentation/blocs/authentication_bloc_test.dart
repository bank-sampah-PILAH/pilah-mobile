import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/domain/use_cases/authentication_use_cases.dart';
import 'package:pilah_mobile/features/authentication/domain/use_cases/login_with_google_usecase.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/login_refresh_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/login_with_google_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/register_google_role_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/post_login_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/states/post_login_states.dart';

class MockAuthenticationUseCases extends Mock
    implements AuthenticationUseCases {}

class MockLoginWithGoogleUseCase extends Mock
    implements LoginWithGoogleUseCase {}

void main() {
  late AuthenticationBloc bloc;
  late MockAuthenticationUseCases mockUseCases;
  late MockLoginWithGoogleUseCase mockLoginWithGoogle;

  setUp(() {
    mockUseCases = MockAuthenticationUseCases();
    mockLoginWithGoogle = MockLoginWithGoogleUseCase();
    bloc = AuthenticationBloc(mockUseCases, mockLoginWithGoogle);
  });

  tearDown(() {
    bloc.close();
  });

  group('AuthenticationBloc', () {
    const tUsername = 'test_user';
    const tPassword = 'password123';
    final tAuth = AuthEntity(
      id: '1',
      name: 'Test User',
      email: 'test@example.com',
      photoUrl: '',
      token: 'access_token',
    );

    test('initial state should be AuthenticationInitial', () {
      expect(bloc.state, isA<AuthenticationInitial>());
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
        verify(() => mockUseCases.saveToken(tAuth.token, tAuth.token))
            .called(1);
      },
    );

    blocTest<AuthenticationBloc, dynamic>(
      'emits [Loading, Error] when login fails',
      build: () {
        when(() => mockUseCases.postLogin(tUsername, tPassword)).thenAnswer(
            (_) async => Left(GeneralException(message: 'Login failed')));
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
        isA<AuthenticationInitial>(),
      ],
    );

    group('Google Login', () {
      const tIdToken = 'mock_google_id_token';
      const tName = 'Test User';
      const tEmail = 'test@example.com';
      const tPhotoUrl = 'https://example.com/photo.png';

      final tAuthEntity = AuthEntity(
        id: '1',
        name: tName,
        email: tEmail,
        photoUrl: tPhotoUrl,
        token: 'access_token',
      );

      blocTest<AuthenticationBloc, dynamic>(
        'emits [Loading, Authenticated] when Google login is successful',
        build: () {
          when(() => mockLoginWithGoogle.execute(tIdToken))
              .thenAnswer((_) async => Right(GoogleSession(tAuthEntity)));
          return bloc;
        },
        act: (bloc) => bloc.add(LoginWithGoogleRequested(
          name: tName,
          email: tEmail,
          photoUrl: tPhotoUrl,
          idToken: tIdToken,
        )),
        expect: () => [
          isA<AuthenticationLoading>(),
          isA<Authenticated>(),
        ],
      );

      final registration = GoogleRegistrationRequired(
        registrationToken: 'signed-token',
        expiresIn: 600,
        name: tName,
        email: tEmail,
        photoUrl: tPhotoUrl,
      );

      blocTest<AuthenticationBloc, dynamic>(
        'emits role selection for an unknown Google account',
        build: () {
          when(() => mockLoginWithGoogle.execute(tIdToken))
              .thenAnswer((_) async => Right(registration));
          return bloc;
        },
        act: (bloc) => bloc.add(LoginWithGoogleRequested(
          name: tName,
          email: tEmail,
          photoUrl: tPhotoUrl,
          idToken: tIdToken,
        )),
        expect: () => [
          isA<AuthenticationLoading>(),
          isA<GoogleRegistrationPending>(),
        ],
      );

      blocTest<AuthenticationBloc, dynamic>(
        'submits the selected role and authenticates the new account',
        build: () {
          when(() => mockLoginWithGoogle.register(
                registrationToken: 'signed-token',
                role: GoogleRegistrationRole.nasabah,
              )).thenAnswer((_) async => Right(tAuthEntity));
          return bloc;
        },
        seed: () => GoogleRegistrationPending(registration: registration),
        act: (bloc) => bloc.add(
          const RegisterGoogleRoleRequested(
            role: GoogleRegistrationRole.nasabah,
          ),
        ),
        expect: () => [
          isA<GoogleRegistrationSubmitting>(),
          isA<Authenticated>(),
        ],
      );

      blocTest<AuthenticationBloc, dynamic>(
        'keeps registration in memory when role submission fails',
        build: () {
          when(() => mockLoginWithGoogle.register(
                registrationToken: 'signed-token',
                role: GoogleRegistrationRole.pengelola,
              )).thenAnswer(
            (_) async => Left(GeneralException(message: 'Network failed')),
          );
          return bloc;
        },
        seed: () => GoogleRegistrationPending(registration: registration),
        act: (bloc) => bloc.add(
          const RegisterGoogleRoleRequested(
            role: GoogleRegistrationRole.pengelola,
          ),
        ),
        expect: () => [
          isA<GoogleRegistrationSubmitting>(),
          isA<GoogleRegistrationFailure>(),
        ],
      );

      blocTest<AuthenticationBloc, dynamic>(
        'clears registration when the signed token is expired',
        build: () {
          final response = Response<dynamic>(
            requestOptions: RequestOptions(path: '/auth/google/register'),
            data: {
              'code': 'registration_token_expired',
              'error': 'Sesi pendaftaran kedaluwarsa',
            },
            statusCode: 400,
          );
          when(() => mockLoginWithGoogle.register(
                registrationToken: 'signed-token',
                role: GoogleRegistrationRole.nasabah,
              )).thenAnswer(
            (_) async => Left(BadRequestException(
              response: response,
              message: 'Sesi pendaftaran kedaluwarsa',
            )),
          );
          return bloc;
        },
        seed: () => GoogleRegistrationPending(registration: registration),
        act: (bloc) => bloc.add(
          const RegisterGoogleRoleRequested(
            role: GoogleRegistrationRole.nasabah,
          ),
        ),
        expect: () => [
          isA<GoogleRegistrationSubmitting>(),
          isA<GoogleRegistrationExpired>(),
        ],
      );

      blocTest<AuthenticationBloc, dynamic>(
        'change account clears the pending registration',
        build: () => bloc,
        seed: () => GoogleRegistrationPending(registration: registration),
        act: (bloc) => bloc.add(const ChangeGoogleAccountRequested()),
        expect: () => [isA<AuthenticationInitial>()],
      );

      blocTest<AuthenticationBloc, dynamic>(
        'emits [Loading, Failure] when Google login fails',
        build: () {
          when(() => mockLoginWithGoogle.execute(tIdToken)).thenAnswer(
              (_) async =>
                  Left(GeneralException(message: 'Google login failed')));
          return bloc;
        },
        act: (bloc) => bloc.add(LoginWithGoogleRequested(
          name: tName,
          email: tEmail,
          photoUrl: tPhotoUrl,
          idToken: tIdToken,
        )),
        expect: () => [
          isA<AuthenticationLoading>(),
          isA<AuthenticationFailure>(),
        ],
      );
    });
  });
}
