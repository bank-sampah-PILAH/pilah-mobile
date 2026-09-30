import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/nasabah/data/datasources/nasabah_remote_data_source.dart';
import 'package:pilah_mobile/features/nasabah/data/repositories/nasabah_repository_impl.dart';

class _MockRemote extends Mock implements NasabahRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late NasabahRepositoryImpl repository;

  setUp(() {
    remote = _MockRemote();
    repository = NasabahRepositoryImpl(remote);
  });

  test('sinkron profil berhasil menjadi Right', () async {
    when(() => remote.sinkronProfil('nasabah-1')).thenAnswer((_) async {});

    final hasil = await repository.sinkronProfilNasabah('nasabah-1');

    expect(hasil.isRight(), isTrue);
    verify(() => remote.sinkronProfil('nasabah-1')).called(1);
  });

  test('sinkron profil yang gagal menjadi Left', () async {
    when(() => remote.sinkronProfil('nasabah-1'))
        .thenAnswer((_) async => throw Exception('jaringan putus'));

    final hasil = await repository.sinkronProfilNasabah('nasabah-1');

    expect(hasil.isLeft(), isTrue);
  });
}
