import 'package:pilah_mobile/features/pengumuman/data/datasources/pengumuman_remote_data_source.dart';
import 'package:pilah_mobile/features/pengumuman/data/repositories/pengumuman_repository_impl.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/cubit/pengumuman_cubit.dart';

import 'stub_api.dart';

/// A real [PengumumanCubit] over the real pengumuman stack, with only HTTP
/// stubbed.
PengumumanCubit buildPengumumanCubit(StubApi api) {
  final repository =
      PengumumanRepositoryImpl(PengumumanRemoteDataSourceImpl(api.network));
  return PengumumanCubit(repository);
}
