// Detail-layanan models for `GET /api/v1/bank-sampah/{id}` (PIL-308).

import 'package:pilah_mobile/features/map/presentation/widgets/location_service.dart';

/// One layanan a bank sampah accepts, with its master price. The directory
/// list does not carry these — only the detail page asks for them.
class LayananEntity {
  final String id;
  final String kode;
  final String namaSampah;
  final String kategori;
  final String deskripsi;

  /// Master IDR/kg, as the backend's decimal string (e.g. `"2000.00"`).
  final String hargaPerKg;

  /// The only satuan the backend sends; informational for now.
  final String satuan;

  const LayananEntity({
    required this.id,
    required this.kode,
    required this.namaSampah,
    required this.kategori,
    required this.deskripsi,
    required this.hargaPerKg,
    required this.satuan,
  });

  factory LayananEntity.fromJson(Map<String, dynamic> json) => LayananEntity(
        id: json['id']?.toString() ?? '',
        kode: json['kode']?.toString() ?? '',
        namaSampah: json['nama_sampah']?.toString() ?? '',
        kategori: json['kategori']?.toString() ?? '',
        deskripsi: (json['deskripsi'] as String?) ?? '',
        hargaPerKg: json['harga_per_kg']?.toString() ?? '0',
        satuan: (json['satuan'] as String?) ?? 'kg',
      );
}

/// One bank sampah as `GET /api/v1/bank-sampah/{id}` answers it: the list
/// fields plus `status` and the active `layanan` list.
class BankSampahDetailEntity {
  final String id;
  final String nama;
  final String alamat;
  final String kota;

  /// Backend enum: `active`, `pending`, `rejected`. A directory-listed bank is
  /// always `active`, so this mainly serves as the detail header's badge.
  final String status;
  final String fotoLogo;

  /// Parsed when the bank has coordinates (PIL-326); null otherwise.
  final ({double latitude, double longitude})? lokasi;
  final List<LayananEntity> layanan;

  const BankSampahDetailEntity({
    required this.id,
    required this.nama,
    required this.alamat,
    required this.kota,
    required this.status,
    required this.fotoLogo,
    required this.layanan,
    this.lokasi,
  });

  factory BankSampahDetailEntity.fromJson(Map<String, dynamic> json) =>
      BankSampahDetailEntity(
        id: json['id']?.toString() ?? '',
        nama: json['nama']?.toString() ?? '',
        alamat: (json['alamat'] as String?) ?? '',
        kota: (json['kota'] as String?) ?? '',
        status: json['status']?.toString() ?? '',
        fotoLogo: (json['foto_logo'] as String?) ?? '',
        lokasi: parseLokasi(json['latitude'], json['longitude']),
        layanan: (json['layanan'] as List<dynamic>? ?? const [])
            .map((item) => LayananEntity.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}
