import 'package:dartz/dartz.dart' show Right;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/nasabah/domain/repositories/nasabah_repository.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/sinkron_profil_nasabah_usecase.dart';

class _MockRepository extends Mock implements NasabahRepository {}

void main() {
  test('meneruskan id nasabah ke repository', () async {
    final repository = _MockRepository();
    when(() => repository.sinkronProfilNasabah('nasabah-1'))
        .thenAnswer((_) async => const Right(null));

    final hasil =
        await SinkronProfilNasabahUseCase(repository).execute('nasabah-1');

    expect(hasil.isRight(), isTrue);
    verify(() => repository.sinkronProfilNasabah('nasabah-1')).called(1);
  });
}
