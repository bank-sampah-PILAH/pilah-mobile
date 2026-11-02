import 'package:pilah_mobile/features/nasabah/data/models/nasabah_model.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';

abstract class NasabahRemoteDataSource {
  /// Satu halaman nasabah milik bank sampah pengurus yang sedang masuk.
  ///
  /// [status] memakai kosakata backend: `aktif`, `tidak_aktif`, `menunggu`,
  /// `ditolak`. [search] diabaikan server bila kurang dari dua karakter.
  Future<HalamanNasabah> getNasabah({
    int page,
    int? pageSize,
    String status,
    String? search,
  });

  /// Legacy one-page snapshot of active nasabah; paginated consumers should
  /// use [getNasabah] with `status: 'aktif'`.
  Future<HalamanNasabah> getActiveNasabah();
  Future<NasabahRingkasan> getNasabahRingkasan(String id);
  Future<NasabahModel> addNasabah(NasabahRequest request);
  Future<NasabahModel> updateNasabah(String id, NasabahRequest request);
  Future<void> setStatus(String id, bool isActive);

  /// Salin profil akun nasabah ke catatan bank sampah ini (satu arah).
  Future<void> sinkronProfil(String id);
  Future<void> approveNasabah(String id, String? catatan);
  Future<void> rejectNasabah(String id, String? catatan);
}
