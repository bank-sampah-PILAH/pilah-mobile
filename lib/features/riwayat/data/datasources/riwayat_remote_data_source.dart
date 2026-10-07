import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/riwayat/domain/entities/riwayat_entities.dart';
import 'package:pilah_mobile/features/statement/data/remote/statement_remote_data_sources.dart';

abstract class RiwayatRemoteDataSource {
  /// One page of the member's setoran history; `hasNext` = more pages.
  Future<RiwayatHistory> history(String membershipId, {int page});

  /// The itemized detail of one setoran, for the bottom sheet.
  Future<RiwayatSetoranDetail> setoranDetail(
    String membershipId,
    String transactionId,
  );

  /// The activity-statement PDF (PIL-315), fetched byte-and-header only.
  Future<RiwayatPdf> exportPdf(String membershipId);
}

/// Speaks the nasabah `me` riwayat endpoints through the authenticated
/// transport. Response models come from the beranda repository file, which
/// stays the single parsing home for this backend's envelope.
@LazySingleton(as: RiwayatRemoteDataSource)
class RiwayatRemoteDataSourceImpl implements RiwayatRemoteDataSource {
  final NetworkService network;

  RiwayatRemoteDataSourceImpl(this.network);

  NasabahRepository get _nasabah => NasabahRepository(network);

  @override
  Future<RiwayatHistory> history(String membershipId, {int page = 1}) async {
    final result = await _nasabah.history(membershipId, page: page);
    return RiwayatHistory(result.activities, result.hasNext);
  }

  @override
  Future<RiwayatSetoranDetail> setoranDetail(
    String membershipId,
    String transactionId,
  ) async =>
      _nasabah.setoranDetail(membershipId, transactionId);

  @override
  Future<RiwayatPdf> exportPdf(String membershipId) async {
    final result =
        await StatementRemoteDataSourceImpl(network).exportPdf(membershipId);
    return RiwayatPdf(
      bytes: Uint8List.fromList(result.bytes),
      filename: result.filename,
    );
  }
}
