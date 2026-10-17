import 'package:dio/dio.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_me_get.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/pengumuman/data/models/pengumuman_page_model.dart';

/// Nasabah-facing pengumuman data (PIL-244), shaped like the beranda
/// [NasabahRepository]: one class over [NetworkService], throwing
/// [NasabahApiException] with Indonesian messages.
class NasabahPengumumanRepository {
  final NetworkService networkService;

  NasabahPengumumanRepository(this.networkService);

  static const _path = '/api/v1/nasabah/me/pengumuman';

  Future<PengumumanPageModel> list({String? membershipId, int page = 1}) async {
    final data = await nasabahMeGet(
      networkService,
      _path,
      membershipId: membershipId,
      page: page,
    );
    return PengumumanPageModel.fromJson(data);
  }

  /// Marks the announcement read; idempotent on the backend, so a repeat
  /// POST is harmless.
  Future<void> tandaiDibaca(String id, {String? membershipId}) async {
    try {
      await networkService.post('$_path/$id/baca', queryParams: {
        if (membershipId != null) 'keanggotaan_id': membershipId,
      });
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      throw NasabahApiException(switch (status) {
        401 => 'Sesi berakhir. Silakan masuk kembali.',
        404 => 'Pengumuman tidak lagi tersedia.',
        _ => 'Penanda sudah dibaca gagal. Coba lagi.',
      });
    }
  }
}
