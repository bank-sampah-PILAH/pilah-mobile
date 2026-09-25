import 'package:pilah_mobile/features/nasabah/data/models/nasabah_model.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';

abstract class NasabahRemoteDataSource {
  /// Satu halaman nasabah milik bank sampah pengurus yang sedang masuk.
  ///
  /// [status] memakai kosakata backend: `aktif`, `tidak_aktif`, `menunggu`,
  /// `ditolak`. [search] diabaikan server bila kurang dari dua karakter.
  Future<HalamanNasabah> getNasabah({
    int page,
    String status,
    String? search,
  });

  /// Seluruh nasabah aktif dalam satu panggilan, untuk picker Transaksi Baru.
  ///
  /// Picker memerlukan semua pilihan sekaligus, jadi ia sengaja tidak memakai
  /// paginasi halaman daftar nasabah (PIL-214).
  Future<HalamanNasabah> getActiveNasabah();
  Future<NasabahRingkasan> getNasabahRingkasan(String id);
  Future<NasabahModel> addNasabah(NasabahRequest request);
  Future<NasabahModel> updateNasabah(String id, NasabahRequest request);
  Future<void> setStatus(String id, bool isActive);
  Future<void> approveNasabah(String id, String? catatan);
  Future<void> rejectNasabah(String id, String? catatan);
}
