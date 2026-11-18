import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/harga/domain/entities/ubah_harga.dart';
import 'package:pilah_mobile/features/harga/domain/repositories/harga_repository.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/ubah_harga_usecase.dart';

class _MockRepository extends Mock implements HargaRepository {}

void main() {
  test('passes the price change to the repository and returns its result',
      () async {
    final repository = _MockRepository();
    const perubahan = UbahHarga(id: 'j-1', harga: 4000);
    final failure = NetworkException(message: 'gagal');
    when(() => repository.ubahHarga(perubahan))
        .thenAnswer((_) async => Left(failure));

    final result = await UbahHargaUseCase(repository).execute(perubahan);

    expect(result, Left<NetworkException, void>(failure));
    verify(() => repository.ubahHarga(perubahan)).called(1);
  });
}
