import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/riwayat/domain/entities/riwayat_entities.dart';
import 'package:pilah_mobile/features/riwayat/domain/repositories/riwayat_repository.dart';

/// Adapts the offline preview fixture to the PIL-315 history contract.
class PreviewRiwayatRepository implements RiwayatRepository {
  PreviewRiwayatRepository(this.source);
  final NasabahRepository source;

  Future<Either<NetworkException, T>> _read<T>(
      Future<T> Function() read) async {
    try {
      return Right(await read());
    } catch (error) {
      return Left(NetworkException(
          message: error is NasabahApiException
              ? error.message
              : 'Tidak ada data preview.'));
    }
  }

  @override
  Future<Either<NetworkException, RiwayatHistory>> history(String membershipId,
          {int page = 1}) =>
      _read(() => source.history(membershipId, page: page));

  @override
  Future<Either<NetworkException, RiwayatSetoranDetail>> setoranDetail(
          String membershipId, String transactionId) =>
      _read(() => source.setoranDetail(membershipId, transactionId));

  @override
  Future<Either<NetworkException, RiwayatPdf>> exportPdf(String membershipId) =>
      _read(() async {
        final pdf = await source.exportPdf(membershipId);
        return RiwayatPdf(
            bytes: Uint8List.fromList(pdf.bytes), filename: pdf.filename);
      });
}
