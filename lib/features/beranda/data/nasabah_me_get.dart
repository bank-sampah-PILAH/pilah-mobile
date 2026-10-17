import 'package:dio/dio.dart';

import '../../../core/client/network_service.dart';
import 'nasabah_repository.dart';

/// One authenticated GET on the nasabah-`me` endpoints, with the platform's
/// shared error mapping (membership picker on 422, safe actionable messages
/// otherwise). Both NasabahRepository and the riwayat datasource read the
/// same backend surface, so the GET lives here instead of twice.
Future<Map<String, dynamic>> nasabahMeGet(
  NetworkService network,
  String path, {
  String? membershipId,
  int? page,
}) async {
  try {
    final response = await network.get(path, queryParams: {
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
