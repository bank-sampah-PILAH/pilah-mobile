import 'package:dartz/dartz.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/riwayat/data/datasources/riwayat_remote_data_source.dart';
import 'package:pilah_mobile/features/riwayat/domain/entities/riwayat_entities.dart';
import 'package:pilah_mobile/features/riwayat/domain/repositories/riwayat_repository.dart';
import 'package:pilah_mobile/features/riwayat/domain/use_cases/riwayat_use_cases.dart';
import 'package:pilah_mobile/features/riwayat/presentation/cubit/riwayat_history_cubit.dart';
import 'package:pilah_mobile/services/di.dart';

/// Fake riwayat layers for screen-level tests. Everything reads one in-memory
/// page list; nothing needs mocking per test. Register in setUp, unregister
/// in tearDown alongside the other DI fakes.
class FakeRiwayatRemoteDataSource implements RiwayatRemoteDataSource {
  FakeRiwayatRemoteDataSource({this.pages = const []});

  /// One list per page number (1-based); a page beyond the list is empty.
  final List<List<NasabahActivity>> pages;
  final requests = <(String, int)>[];

  @override
  Future<RiwayatHistory> history(String membershipId, {int page = 1}) async {
    requests.add((membershipId, page));
    final List<NasabahActivity> rows =
        pages.length >= page ? pages[page - 1] : const [];
    return RiwayatHistory(rows, page <= pages.length - 1 || hasNextOverride);
  }

  /// Force an extra page even when the fixture list ran out.
  bool hasNextOverride = false;

  @override
  Future<RiwayatSetoranDetail> setoranDetail(
          String membershipId, String transactionId) =>
      throw UnsupportedError('No detail fixture in this test');

  @override
  Future<RiwayatPdf> exportPdf(String membershipId) =>
      throw UnsupportedError('No export fixture in this test');
}

void registerFakeRiwayat(FakeRiwayatRemoteDataSource source) {
  di.registerSingleton<RiwayatRemoteDataSource>(source);
  di.registerLazySingleton<RiwayatRepository>(
    () => _FixedRepository(source),
  );
  // The history screen resolves this factory; use cases wire the fake repo.
  di.registerFactory<RiwayatHistoryCubit>(
    () => RiwayatHistoryCubit(
      GetRiwayatHistoryUseCase(di<RiwayatRepository>()),
      GetRiwayatSetoranDetailUseCase(di<RiwayatRepository>()),
    ),
  );
}

Future<void> unregisterFakeRiwayat() async {
  await di.unregister<RiwayatHistoryCubit>();
  await di.unregister<RiwayatRepository>();
  await di.unregister<RiwayatRemoteDataSource>();
}

class _FixedRepository implements RiwayatRepository {
  _FixedRepository(this._source);
  final FakeRiwayatRemoteDataSource _source;

  @override
  Future<Either<NetworkException, RiwayatHistory>> history(
    String membershipId, {
    int page = 1,
  }) async =>
      Right(await _source.history(membershipId, page: page));

  @override
  Future<Either<NetworkException, RiwayatSetoranDetail>> setoranDetail(
          String membershipId, String transactionId) async =>
      Left(NetworkException(message: 'Tidak ada data uji'));

  @override
  Future<Either<NetworkException, RiwayatPdf>> exportPdf(
          String membershipId) async =>
      Left(NetworkException(message: 'Tidak ada data uji'));
}