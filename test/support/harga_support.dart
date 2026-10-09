import 'package:pilah_mobile/features/harga/data/datasources/harga_remote_data_source_impl.dart';
import 'package:pilah_mobile/features/harga/data/repositories/harga_repository_impl.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/activate_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/add_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/deactivate_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/get_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/ubah_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/update_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';

import 'stub_api.dart';

/// A real [HargaCubit] over the real harga stack, with only HTTP stubbed.
HargaCubit buildHargaCubit(StubApi api) {
  final repository =
      HargaRepositoryImpl(HargaRemoteDataSourceImpl(api.network));
  return HargaCubit(
    GetHargaUseCase(repository),
    AddHargaUseCase(repository),
    UpdateHargaUseCase(repository),
    DeactivateHargaUseCase(repository),
    ActivateHargaUseCase(repository),
    UbahHargaUseCase(repository),
  );
}
