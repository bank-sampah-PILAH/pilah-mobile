import 'package:dio/dio.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_me_get.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/pengumuman/data/models/pengumuman_page_model.dart';

/// One row of the beranda summary (PIL-333): what shows on the home screen.
class PengumumanBerandaItem {
  const PengumumanBerandaItem({
    required this.id,
    required this.judul,
    required this.isi,
    required this.terbitPada,
    this.dibaca = false,
  });

  factory PengumumanBerandaItem.fromJson(Map<String, dynamic> json) =>
      PengumumanBerandaItem(
        id: json['id'] as String,
        judul: json['judul'] as String,
        isi: json['isi'] as String? ?? '',
        terbitPada: json['terbit_pada'] == null
            ? null
            : DateTime.parse(json['terbit_pada'] as String),
        dibaca: json['dibaca'] as bool? ?? false,
      );

  final String id;
  final String judul;
  final String isi;
  final DateTime? terbitPada;
  final bool dibaca;
}

/// The beranda section's payload: the last few rows plus how many active
/// announcements of the whole set remain unread.
class PengumumanBeranda {
  const PengumumanBeranda({required this.items, required this.unreadCount});

  factory PengumumanBeranda.fromJson(Map<String, dynamic> json) =>
      PengumumanBeranda(
        items: (json['items'] as List)
            .map((item) =>
                PengumumanBerandaItem.fromJson(item as Map<String, dynamic>))
            .toList(),
        unreadCount: json['unread_count'] as int? ?? 0,
      );

  final List<PengumumanBerandaItem> items;
  final int unreadCount;
}

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

  /// The beranda section payload (PIL-333).
  Future<PengumumanBeranda> getBeranda({String? membershipId}) async {
    final data = await nasabahMeGet(
      networkService,
      '$_path/beranda',
      membershipId: membershipId,
    );
    return PengumumanBeranda.fromJson(data);
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
