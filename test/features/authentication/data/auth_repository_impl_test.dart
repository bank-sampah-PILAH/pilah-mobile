import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/authentication/data/auth_repository_impl.dart';
import 'package:pilah_mobile/features/authentication/data/local/auth_local_data_sources.dart';
import 'package:pilah_mobile/features/authentication/data/remote/auth_remote_data_sources.dart';

class _MockAuthRemote extends Mock implements AuthRemoteDataSources {}

class _MockAuthLocal extends Mock implements AuthLocalDataSources {}

void main() {
  late _MockAuthRemote remote;
  late _MockAuthLocal local;
  late AuthRepositoryImpl repo;

  setUp(() {
    remote = _MockAuthRemote();
    local = _MockAuthLocal();
    repo = AuthRepositoryImpl(remote, local);
  });

  group('loginWithGoogle error handling', () {
    test('surfaces a parse Error as a Left instead of throwing (M1)', () async {
      // A malformed 2xx body makes AuthResponse.fromJson throw a
      // TypeError/CastError — a Dart *Error*, not an Exception. The old
      // `on Exception` guard missed it and crashed the login screen. ArgumentError
      // stands in for that class of failure (an Error, not an Exception).
      when(() => remote.loginWithGoogle(any()))
          .thenThrow(ArgumentError('malformed 2xx body'));

      // The assertion is that this line does not throw.
      final result = await repo.loginWithGoogle('id-token');

      expect(result.isLeft(), isTrue);
      expect(result, isA<Left>());
    });

    test('still maps a normal Exception to a Left', () async {
      when(() => remote.loginWithGoogle(any()))
          .thenThrow(Exception('network down'));

      final result = await repo.loginWithGoogle('id-token');

      expect(result.isLeft(), isTrue);
    });
  });
}
