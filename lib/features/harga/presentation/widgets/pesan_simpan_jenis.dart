import 'package:pilah_mobile/core/utils/formatter/wa_template_renderer.dart';

/// Pesan konfirmasi setelah jenis sampah disimpan dari sheet tambah/edit.
///
/// Harga terjadwal menyebut tanggal mulainya, supaya pengurus tahu harga lama
/// masih dipakai sampai tanggal itu.
String pesanSimpanJenis({
  required bool isEditMode,
  required bool hargaBerubah,
  DateTime? berlakuMulai,
}) {
  if (!isEditMode) return 'Jenis sampah baru berhasil ditambahkan.';
  if (hargaBerubah && berlakuMulai != null) {
    return 'Harga baru berlaku mulai ${formatTanggalId(berlakuMulai)}.';
  }
  return 'Jenis sampah berhasil diperbarui.';
}
