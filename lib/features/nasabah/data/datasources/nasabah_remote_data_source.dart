import 'package:pilah_mobile/features/nasabah/data/models/nasabah_model.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';

abstract class NasabahRemoteDataSource {
  /// Satu halaman nasabah milik bank sampah pengurus yang sedang masuk.
  ///
  /// [status] memakai kosakata backend: `aktif`, `tidak_aktif`, `menunggu`,
  /// `ditolak`. [search] diabaikan server bila kurang dari dua karakter.
  Future<NasabahPage> getNasabah({
    int page,
    String status,
    String? search,
  });
  Future<NasabahRingkasan> getNasabahRingkasan(String id);
  Future<NasabahModel> addNasabah(NasabahRequest request);
  Future<NasabahModel> updateNasabah(String id, NasabahRequest request);
  Future<void> setStatus(String id, bool isActive);
  Future<void> approveNasabah(String id, String? catatan);
  Future<void> rejectNasabah(String id, String? catatan);
}
