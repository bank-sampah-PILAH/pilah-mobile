import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/domain/repository/auth_repository.dart';
import 'package:pilah_mobile/features/authentication/domain/use_cases/login_with_google_usecase.dart';

import '../../../support/auth_support.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late LoginWithGoogleUseCase useCase;

  setUp(() {
    repository = _MockAuthRepository();
    useCase = LoginWithGoogleUseCase(repository);
  });

  test('exchanges the Google ID token for a session', () async {
    final session = GoogleSession(testAuth());
    when(() => repository.loginWithGoogle('id-token'))
        .thenAnswer((_) async => Right(session));

    final result = await useCase.execute('id-token');

    expect(result, Right<Object, GoogleAuthOutcome?>(session));
  });

  test('treats a missing token as an empty one', () async {
    when(() => repository.loginWithGoogle(''))
        .thenAnswer((_) async => Right(GoogleSession(testAuth())));

    await useCase.execute();

    verify(() => repository.loginWithGoogle('')).called(1);
  });

  test('registers the chosen role with the signed registration token',
      () async {
    final auth = testAuth(role: 'nasabah');
    when(() => repository.registerGoogleUser(
          registrationToken: 'signed',
          role: GoogleRegistrationRole.nasabah,
        )).thenAnswer((_) async => Right(auth));

    final result = await useCase.register(
        registrationToken: 'signed', role: GoogleRegistrationRole.nasabah);

    expect(result.getOrElse(() => throw 'failed'), auth);
  });
}
