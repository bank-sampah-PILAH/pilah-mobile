import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart'
    show NasabahApiException;
import 'package:pilah_mobile/features/riwayat/data/datasources/riwayat_remote_data_source.dart';
import 'package:pilah_mobile/features/riwayat/domain/entities/riwayat_entities.dart';
import 'package:pilah_mobile/features/riwayat/domain/repositories/riwayat_repository.dart';

@LazySingleton(as: RiwayatRepository)
class RiwayatRepositoryImpl implements RiwayatRepository {
  final RiwayatRemoteDataSource _remote;

  const RiwayatRepositoryImpl(this._remote);

  /// The nasabah-me GET raises [NasabahApiException] carrying the safe
  /// per-status Indonesian message; a generic stringify-and-wrap (the other
  /// apiCall-style paths) would flatten it to "Instance of ...". Map it to a
  /// [NetworkException] with the message intact; everything else follows the
  /// shared bad-response/timeout mapping.
  Future<Either<NetworkException, T>> _call<T>(
      Future<T> Function() request) async {
    try {
      return Right(await request());
    } on NasabahApiException catch (error) {
      return Left(NetworkException(message: error.message));
    } on DioException catch (error) {
      return Left(NetworkException.handleException(error));
    } catch (error) {
      return Left(GeneralException(message: error.toString()));
    }
  }

  @override
  Future<Either<NetworkException, RiwayatHistory>> history(
    String membershipId, {
    int page = 1,
  }) =>
      _call(() => _remote.history(membershipId, page: page));

  @override
  Future<Either<NetworkException, RiwayatSetoranDetail>> setoranDetail(
    String membershipId,
    String transactionId,
  ) =>
      _call(() => _remote.setoranDetail(membershipId, transactionId));
}
