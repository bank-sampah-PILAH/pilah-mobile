import 'package:pilah_mobile/features/harga/domain/entities/versi_harga.dart';

/// Satu baris `GET /jenis-sampah/{id}/harga` sebagai [VersiHarga].
///
/// Status yang belum dikenal aplikasi dibaca "sebelumnya": netral, tidak
/// mengklaim harga itu berlaku atau terjadwal.
VersiHarga versiHargaFromJson(Map<String, dynamic> json) {
  return VersiHarga(
    hargaSen: _keSen(json['harga_per_kg']?.toString() ?? '0'),
    satuan: json['satuan'] as String? ?? 'kg',
    berlakuMulai: DateTime.parse(json['berlaku_mulai'] as String),
    dibuatOleh: json['dibuat_oleh'] as String?,
    status: StatusVersiHarga.values.asNameMap()[json['status']] ??
        StatusVersiHarga.sebelumnya,
  );
}

/// `"3333.99"` menjadi `333399` dengan memotong teks, bukan lewat `double`.
int _keSen(String angka) {
  final bagian = angka.split('.');
  final sen = (bagian.length > 1 ? bagian[1] : '').padRight(2, '0');
  return (int.tryParse(bagian[0]) ?? 0) * 100 +
      (int.tryParse(sen.substring(0, 2)) ?? 0);
}
