import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/api_call.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/nasabah/data/datasources/nasabah_remote_data_source.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/domain/repositories/nasabah_repository.dart';

@LazySingleton(as: NasabahRepository)
class NasabahRepositoryImpl implements NasabahRepository {
  final NasabahRemoteDataSource remoteDataSource;

  NasabahRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<NetworkException, HalamanNasabah>> getNasabah({
    int page = 1,
    int? pageSize,
    String status = 'aktif',
    String? search,
    String urutan = 'nomor',
  }) async {
    try {
      return Right(await remoteDataSource.getNasabah(
        page: page,
        pageSize: pageSize,
        status: status,
        search: search,
        urutan: urutan,
      ));
    } catch (error) {
      // List errors can include HTML error pages, decoder source text or
      // backend diagnostics. Only fixed messages cross into presentation.
      return Left(GeneralException(message: _listErrorMessage(error)));
    }
  }

  static String _listErrorMessage(Object error) {
    const failed = 'Daftar nasabah gagal dimuat. Silakan coba lagi.';
    const timeout =
        'Permintaan daftar nasabah terlalu lama. Silakan coba lagi.';
    if (error is TimeoutException) return timeout;
    if (error is! DioException) return failed;
    if (error.error is TimeoutException) return timeout;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return timeout;
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung. Periksa koneksi lalu coba lagi.';
      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';
      case DioExceptionType.badCertificate:
        return 'Koneksi aman tidak dapat diverifikasi.';
      case DioExceptionType.badResponse:
        return switch (error.response?.statusCode) {
          401 => 'Sesi Anda telah berakhir. Silakan masuk kembali.',
          403 => 'Anda tidak memiliki akses ke daftar nasabah ini.',
          400 || 422 => 'Pencarian atau filter nasabah tidak valid.',
          429 => 'Terlalu banyak permintaan. Tunggu sebentar lalu coba lagi.',
          _ => failed,
        };
      case DioExceptionType.unknown:
        return failed;
    }
  }

  @override
  Future<Either<NetworkException, HalamanNasabah>> getActiveNasabah() {
    return apiCall<HalamanNasabah>(
      func: remoteDataSource.getActiveNasabah(),
      mapper: (result) => result as HalamanNasabah,
    );
  }

  @override
  Future<Either<NetworkException, NasabahRingkasan>> getNasabahRingkasan(
      String id) {
    return apiCall<NasabahRingkasan>(
      func: remoteDataSource.getNasabahRingkasan(id),
      mapper: (result) => result as NasabahRingkasan,
    );
  }

  @override
  Future<Either<NetworkException, NasabahEntity>> addNasabah(
      NasabahRequest request) {
    return apiCall<NasabahEntity>(
      func: remoteDataSource.addNasabah(request),
      mapper: (result) => result as NasabahEntity,
    );
  }

  @override
  Future<Either<NetworkException, NasabahEntity>> updateNasabah(
    String id,
    NasabahRequest request,
  ) {
    return apiCall<NasabahEntity>(
      func: remoteDataSource.updateNasabah(id, request),
      mapper: (result) => result as NasabahEntity,
    );
  }

  @override
  Future<Either<NetworkException, void>> sinkronProfilNasabah(String id) async {
    try {
      await remoteDataSource.sinkronProfil(id);
      return const Right(null);
    } on Exception catch (e) {
      return Left(NetworkException.handleException(e));
    }
  }

  @override
  Future<Either<NetworkException, void>> activateNasabah(String id) async {
    try {
      await remoteDataSource.setStatus(id, true);
      return const Right(null);
    } on Exception catch (e) {
      return Left(NetworkException.handleException(e));
    }
  }

  @override
  Future<Either<NetworkException, void>> deactivateNasabah(String id) async {
    try {
      await remoteDataSource.setStatus(id, false);
      return const Right(null);
    } on Exception catch (e) {
      return Left(NetworkException.handleException(e));
    }
  }

  @override
  Future<Either<NetworkException, void>> approveNasabah(
    String id, {
    String? catatan,
  }) async {
    try {
      await remoteDataSource.approveNasabah(id, catatan);
      return const Right(null);
    } on Exception catch (e) {
      return Left(NetworkException.handleException(e));
    }
  }

  @override
  Future<Either<NetworkException, void>> rejectNasabah(
    String id, {
    String? catatan,
  }) async {
    try {
      await remoteDataSource.rejectNasabah(id, catatan);
      return const Right(null);
    } on Exception catch (e) {
      return Left(NetworkException.handleException(e));
    }
  }
}
