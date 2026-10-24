import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/domain/entities/ubah_harga.dart';
import 'package:pilah_mobile/features/harga/presentation/states/harga_state.dart';
import 'package:pilah_mobile/features/harga/data/datasources/harga_remote_data_source_impl.dart';
import 'package:pilah_mobile/features/harga/data/repositories/harga_repository_impl.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/activate_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/add_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/deactivate_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/get_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/ubah_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/update_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/presentation/providers/harga_provider.dart';
import 'package:pilah_mobile/features/harga/presentation/providers/riwayat_harga_provider.dart';

import 'stub_api.dart';

Widget withHargaProvider(HargaNotifier notifier, Widget child) => ProviderScope(
      overrides: [hargaProvider.overrideWith(() => notifier)],
      child: child,
    );

Widget withRiwayatHargaProvider(
  RiwayatHargaNotifier notifier,
  Widget child,
) =>
    ProviderScope(
      overrides: [riwayatHargaProvider.overrideWith(() => notifier)],
      child: child,
    );

class TestHargaNotifier extends HargaNotifier {
  TestHargaNotifier(
    HargaNotifier delegate, {
    HargaState? initialState,
  })  : initialState = initialState ?? HargaInitial(),
        super(
          delegate.getHargaUseCase,
          delegate.addHargaUseCase,
          delegate.updateHargaUseCase,
          delegate.deactivateHargaUseCase,
          delegate.activateHargaUseCase,
          delegate.ubahHargaUseCase,
        );

  final HargaState initialState;
  final calls = <String>[];
  final updated = <HargaEntity>[];
  NetworkException? priceChangeError;
  final changed = <UbahHarga>[];

  @override
  HargaState build() => initialState;

  @override
  Future<void> loadHarga({bool silent = false}) async =>
      calls.add('load:$silent');

  @override
  Future<NetworkException?> addHarga(HargaEntity harga) async {
    updated.add(harga);
    calls.add('add');
    return null;
  }

  @override
  Future<NetworkException?> updateHarga(HargaEntity harga) async {
    updated.add(harga);
    calls.add('update');
    return null;
  }

  @override
  Future<NetworkException?> ubahHarga(UbahHarga perubahan) async {
    changed.add(perubahan);
    calls.add('ubah');
    return priceChangeError;
  }
}

/// A real [HargaNotifier] over the harga stack, with only HTTP stubbed.
HargaNotifier buildHargaNotifier(StubApi api) {
  final repository =
      HargaRepositoryImpl(HargaRemoteDataSourceImpl(api.network));
  return HargaNotifier(
    GetHargaUseCase(repository),
    AddHargaUseCase(repository),
    UpdateHargaUseCase(repository),
    DeactivateHargaUseCase(repository),
    ActivateHargaUseCase(repository),
    UbahHargaUseCase(repository),
  );
}
