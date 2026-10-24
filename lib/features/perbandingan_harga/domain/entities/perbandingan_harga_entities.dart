/// Models of `GET /api/v1/bank-sampah/harga-perbandingan` (PIL-309).
class PerbandinganJenisEntity {
  final String id;
  final String nomor;
  final String namaSampah;
  final String kategori;
  final String satuan;

  const PerbandinganJenisEntity({
    required this.id,
    required this.nomor,
    required this.namaSampah,
    required this.kategori,
    required this.satuan,
  });

  factory PerbandinganJenisEntity.fromJson(Map<String, dynamic> json) =>
      PerbandinganJenisEntity(
        id: json['id']?.toString() ?? '',
        nomor: json['nomor']?.toString() ?? '',
        namaSampah: json['nama_sampah']?.toString() ?? '',
        kategori: json['kategori']?.toString() ?? '',
        satuan: json['satuan']?.toString() ?? 'kg',
      );
}

/// One bank row of the comparison: a price, or `hargaTidakTersedia` with the
/// reason (`tanpa_jenis` | `jenis_nonaktif` | `belum_ada_harga` | null).
class PerbandinganBankHargaEntity {
  final String bankSampahId;
  final String? nama;
  final String? kota;
  final String? hargaPerKg;
  final String? berlakuMulai;
  final bool hargaTidakTersedia;
  final String? alasan;

  const PerbandinganBankHargaEntity({
    required this.bankSampahId,
    required this.nama,
    required this.kota,
    required this.hargaPerKg,
    required this.berlakuMulai,
    required this.hargaTidakTersedia,
    required this.alasan,
  });

  factory PerbandinganBankHargaEntity.fromJson(Map<String, dynamic> json) =>
      PerbandinganBankHargaEntity(
        bankSampahId: json['bank_sampah_id']?.toString() ?? '',
        nama: json['nama']?.toString(),
        kota: json['kota']?.toString(),
        hargaPerKg: json['harga_per_kg']?.toString(),
        berlakuMulai: json['berlaku_mulai']?.toString(),
        hargaTidakTersedia: json['harga_tidak_tersedia'] == true,
        alasan: json['alasan']?.toString(),
      );
}

/// The whole envelope: the echoed jenis plus one row per compared bank.
class PerbandinganHargaEntity {
  final PerbandinganJenisEntity jenisSampah;
  final List<PerbandinganBankHargaEntity> perbandingan;

  const PerbandinganHargaEntity({
    required this.jenisSampah,
    required this.perbandingan,
  });

  factory PerbandinganHargaEntity.fromJson(Map<String, dynamic> json) =>
      PerbandinganHargaEntity(
        jenisSampah: PerbandinganJenisEntity.fromJson(
            json['jenis_sampah'] as Map<String, dynamic>),
        perbandingan: ((json['perbandingan'] as List<dynamic>?) ?? const [])
            .map((row) => PerbandinganBankHargaEntity.fromJson(
                row as Map<String, dynamic>))
            .toList(),
      );
}
