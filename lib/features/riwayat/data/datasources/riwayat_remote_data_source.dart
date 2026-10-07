import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
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

  /// Shared GET + error mapping, identical language to NasabahRepository's
  /// method (the same backend surface), without importing its HTTP class.
  Future<Map<String, dynamic>> _get(
    String path, {
    String? membershipId,
    int? page,
  }) async {
    try {
      final response = await network.get('$_base/$path', queryParams: {
        if (membershipId != null) 'keanggotaan_id': membershipId,
        if (page != null) 'page': page,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      final errors = data is Map ? data['errors'] : null;
      final choices = errors is Map ? errors['pilihan'] : null;
      if (status == 422 && choices is List && choices.isNotEmpty) {
        throw NasabahApiException('Pilih bank sampah Anda.',
            choices: choices
                .map((v) => MembershipChoice(
                    v['id'] as String, v['bank_sampah_nama'] as String))
                .toList());
      }
      throw NasabahApiException(switch (status) {
        401 => 'Sesi berakhir. Silakan masuk kembali.',
        403 =>
          'Akses belum tersedia. Pastikan akun, keanggotaan, dan bank sampah aktif.',
        404 => 'Data tidak ditemukan. Muat ulang atau pilih keanggotaan lain.',
        422 => 'Pilihan keanggotaan tidak valid. Silakan pilih kembali.',
        _ => 'Data gagal dimuat. Periksa koneksi dan coba lagi.',
      });
    }
  }
}
