import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_me_get.dart';
import 'package:pilah_mobile/features/riwayat/domain/entities/riwayat_entities.dart';

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

  static const _base = '/api/v1/nasabah/me';

  @override
  Future<RiwayatHistory> history(String membershipId, {int page = 1}) async {
    final json = await _get('riwayat', membershipId: membershipId, page: page);
    return RiwayatHistory(
      (json['results'] as List)
          .map((v) => NasabahActivity.fromJson(v as Map<String, dynamic>))
          .toList(),
      json['next'] != null,
    );
  }

  @override
  Future<RiwayatSetoranDetail> setoranDetail(
    String membershipId,
    String transactionId,
  ) async =>
      RiwayatSetoranDetail.fromJson(
        await _get('riwayat/$transactionId', membershipId: membershipId),
      );

  @override
  Future<RiwayatPdf> exportPdf(String membershipId) async {
    final response = await network.getBytes(
      '$_base/riwayat/export-pdf',
      queryParams: {'keanggotaan_id': membershipId},
    );
    final data = response.data;
    final bytes = data is Uint8List
        ? data
        : Uint8List.fromList((data as List).cast<int>());
    return RiwayatPdf(
      bytes: bytes,
      filename: _attachmentName(response),
    );
  }

  /// Filename from `Content-Disposition: attachment; filename="x.pdf"`, with
  /// a fixed default — the backend always sends the header, but a proxy
  /// stripping it must not defeat the save.
  String _attachmentName(Response response) {
    final header = response.headers.value('content-disposition');
    final match = header == null
        ? null
        : RegExp(r'filename="?([^";]+)"?$').firstMatch(header);
    return match?.group(1) ?? 'Riwayat_Aktivitas.pdf';
  }

  /// Shared GET + error mapping — the same nasabah-me surface as
  /// NasabahRepository, so both route through the one implementation.
  Future<Map<String, dynamic>> _get(
    String path, {
    String? membershipId,
    int? page,
  }) =>
      nasabahMeGet(network, '$_base/$path',
          membershipId: membershipId, page: page);
}
