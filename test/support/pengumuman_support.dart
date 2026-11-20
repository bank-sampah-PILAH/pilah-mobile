import 'package:pilah_mobile/features/pengumuman/data/datasources/pengumuman_remote_data_source.dart';
import 'package:pilah_mobile/features/pengumuman/data/repositories/pengumuman_repository_impl.dart';
import 'package:pilah_mobile/features/pengumuman/domain/repositories/pengumuman_repository.dart';

import 'stub_api.dart';

/// A real repository over the pengumuman stack, with only HTTP stubbed.
PengumumanRepository buildPengumumanRepository(StubApi api) =>
    PengumumanRepositoryImpl(PengumumanRemoteDataSourceImpl(api.network));
