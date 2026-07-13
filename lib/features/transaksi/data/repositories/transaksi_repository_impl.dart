import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/api_call.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/transaksi/data/datasources/transaksi_remote_data_source.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';
import 'package:pilah_mobile/features/transaksi/domain/repositories/transaksi_repository.dart';

@LazySingleton(as: TransaksiRepository)
class TransaksiRepositoryImpl implements TransaksiRepository {
  final TransaksiRemoteDataSource remoteDataSource;

  TransaksiRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<NetworkException, List<TransaksiGroupEntity>>> getTransaksi(
    TransaksiFilter filter,
  ) {
    return apiCall<List<TransaksiGroupEntity>>(
      func: remoteDataSource.getTransaksi(filter),
      mapper: (result) => (result as List).cast<TransaksiGroupEntity>(),
    );
  }

  @override
  Future<Either<NetworkException, TransaksiCreated>> addTransaksi(TransaksiRequest request) {
    return apiCall<TransaksiCreated>(
      func: remoteDataSource.addTransaksi(request),
      mapper: (result) => result as TransaksiCreated,
    );
  }

  @override
  Future<Either<NetworkException, TransaksiDetailEntity>> getTransaksiDetail(String id) {
    return apiCall<TransaksiDetailEntity>(
      func: remoteDataSource.getTransaksiDetail(id),
      mapper: (result) => result as TransaksiDetailEntity,
    );
  }

  @override
  Future<Either<NetworkException, TransaksiExport>> exportTransaksi(
    TransaksiFilter filter,
  ) async {
    try {
      final export = await remoteDataSource.exportTransaksi(filter);
      return Right(export);
    } on DioException catch (e) {
      return Left(_exportError(e));
    } on Exception catch (e) {
      return Left(NetworkException.handleException(e));
    }
  }

  /// The export uses a bytes response type, so an error body (e.g. the 400
  /// "Tidak ada data pada periode ini") arrives as raw bytes rather than a
  /// parsed Map — decode it here so the user sees the real message.
  NetworkException _exportError(DioException e) {
    final data = e.response?.data;
    if (data is List<int>) {
      try {
        final decoded = jsonDecode(utf8.decode(data));
        if (decoded is Map && decoded['error'] != null) {
          return NetworkException(message: decoded['error'].toString());
        }
      } catch (_) {
        // fall through to the generic handler
      }
    }
    return NetworkException.handleException(e);
  }
}
