import 'package:pilah_mobile/features/pencairan/data/pencairan_repository_impl.dart';
import 'package:pilah_mobile/features/pencairan/data/remote/pencairan_remote_data_sources.dart';
import 'package:pilah_mobile/features/pencairan/domain/pencairan_interactor.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';

import 'stub_api.dart';

/// The real pencairan use cases over the real data source, HTTP stubbed.
PencairanUseCases buildPencairanUseCases(StubApi api) => PencairanInteractor(
    PencairanRepositoryImpl(PencairanRemoteDataSourceImpl(api.network)));
