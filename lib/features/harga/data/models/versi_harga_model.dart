import 'package:pilah_mobile/features/harga/domain/entities/versi_harga.dart';

/// Satu baris `GET /jenis-sampah/{id}/harga` sebagai [VersiHarga].
///
/// Status yang belum dikenal aplikasi dibaca "sebelumnya": netral, tidak
/// mengklaim harga itu berlaku atau terjadwal.
VersiHarga versiHargaFromJson(Map<String, dynamic> json) {
  return VersiHarga(
    harga:
        double.tryParse(json['harga_per_kg']?.toString() ?? '')?.toInt() ?? 0,
    satuan: json['satuan'] as String? ?? 'kg',
    berlakuMulai: DateTime.parse(json['berlaku_mulai'] as String),
    dibuatOleh: json['dibuat_oleh'] as String?,
    status: StatusVersiHarga.values.asNameMap()[json['status']] ??
        StatusVersiHarga.sebelumnya,
  );
}
