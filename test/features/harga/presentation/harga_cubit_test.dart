import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/domain/entities/ubah_harga.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/activate_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/add_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/deactivate_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/get_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/ubah_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/update_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_state.dart';

class _MockGet extends Mock implements GetHargaUseCase {}

class _MockAdd extends Mock implements AddHargaUseCase {}

class _MockUpdate extends Mock implements UpdateHargaUseCase {}

class _MockDeactivate extends Mock implements DeactivateHargaUseCase {}

class _MockActivate extends Mock implements ActivateHargaUseCase {}

class _MockUbah extends Mock implements UbahHargaUseCase {}

void main() {
  late _MockGet getHarga;
  late _MockUbah ubahHarga;
  late HargaCubit cubit;
  final perubahan = UbahHarga(
    id: 'j-1',
    harga: 5000,
    berlakuMulai: DateTime(2026, 10, 15),
  );

  setUpAll(() => registerFallbackValue(perubahan));

  setUp(() {
    getHarga = _MockGet();
    ubahHarga = _MockUbah();
    cubit = HargaCubit(
      getHarga,
      _MockAdd(),
      _MockUpdate(),
      _MockDeactivate(),
      _MockActivate(),
      ubahHarga,
    );
    when(() => getHarga.execute())
        .thenAnswer((_) async => const Right(<HargaEntity>[]));
  });

  tearDown(() => cubit.close());

  test('changes the price and reloads the list', () async {
    when(() => ubahHarga.execute(any()))
        .thenAnswer((_) async => const Right(null));

    final error = await cubit.ubahHarga(perubahan);

    expect(error, isNull);
    verify(() => ubahHarga.execute(perubahan)).called(1);
    verify(() => getHarga.execute()).called(1);
  });

  test('returns the failure and keeps the list as it is', () async {
    final failure =
        NetworkException(message: 'Harga tidak boleh berlaku surut');
    when(() => ubahHarga.execute(any())).thenAnswer((_) async => Left(failure));

    final error = await cubit.ubahHarga(perubahan);

    expect(error, failure);
    verifyNever(() => getHarga.execute());
  });

  test('an older reload that answers late never overwrites a newer one',
      () async {
    // Saving a price change reloads after the PUT and again after the POST;
    // the first GET can answer last, with the old price.
    HargaEntity jenis(int harga) => HargaEntity(
          id: 'j-1',
          kodeSampah: 'PLS-001',
          name: 'Plastik PET',
          price: harga,
          priceFormatted: 'Rp $harga',
          category: 'plastik',
          subtitle: '',
          badgeText: 'Anorganik',
          icon: Icons.recycling,
          iconColor: Colors.green,
          isActive: true,
        );
    final lama = Completer<Either<NetworkException, List<HargaEntity>>>();
    final baru = Completer<Either<NetworkException, List<HargaEntity>>>();
    final jawaban = [lama, baru];
    when(() => getHarga.execute())
        .thenAnswer((_) => jawaban.removeAt(0).future);

    final pertama = cubit.loadHarga();
    final kedua = cubit.loadHarga();
    baru.complete(Right([jenis(5000)]));
    await kedua;
    lama.complete(Right([jenis(3500)]));
    await pertama;

    final loaded = cubit.state as HargaLoaded;
    expect(loaded.jenisSampahList.single.price, 5000);
  });
}
