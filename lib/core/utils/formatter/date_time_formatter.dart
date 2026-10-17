import 'package:pilah_mobile/core/utils/formatter/wa_template_renderer.dart';

/// Tulis [waktu] sebagai ISO 8601 lengkap dengan offset zona waktunya,
/// misalnya `2026-10-15T00:00:00+07:00`.
///
/// `DateTime.toIso8601String()` menghilangkan offset pada waktu lokal, dan
/// backend menolak waktu tanpa offset karena tidak tahu zona waktunya
/// (bank sampah bisa berada di WIB, WITA, atau WIT).
String isoDenganOffset(DateTime waktu) {
  String dua(int n) => n.toString().padLeft(2, '0');
  final offset = waktu.timeZoneOffset;
  final tanda = offset.isNegative ? '-' : '+';
  final menit = offset.inMinutes.abs();
  return '${waktu.year.toString().padLeft(4, '0')}-${dua(waktu.month)}-'
      '${dua(waktu.day)}T${dua(waktu.hour)}:${dua(waktu.minute)}:'
      '${dua(waktu.second)}$tanda${dua(menit ~/ 60)}:${dua(menit % 60)}';
}

/// Tanggal dan jam [waktu] seperti `1 Oktober 2026, 09:30`, tanpa mengubah
/// zona waktunya; panggil `toLocal()` lebih dulu untuk waktu dari backend.
String formatTanggalJamId(DateTime waktu) {
  final jam = waktu.hour.toString().padLeft(2, '0');
  final menit = waktu.minute.toString().padLeft(2, '0');
  return '${formatTanggalId(waktu)}, $jam:$menit';
}
