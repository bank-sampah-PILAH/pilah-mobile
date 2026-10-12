import 'package:pilah_mobile/core/utils/formatter/wa_template_renderer.dart';

const _bulan = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// `Rp 138.500`, the way the rest of the app writes money.
String rupiah(int value) => 'Rp ${formatRupiahId(value)}';

/// `7 Okt 2026, 09:05`, or an empty string when the time is unknown.
String waktu(DateTime? value) {
  if (value == null) return '';
  String dua(int n) => n.toString().padLeft(2, '0');
  return '${value.day} ${_bulan[value.month - 1]} ${value.year}, '
      '${dua(value.hour)}:${dua(value.minute)}';
}

const _bulanPenuh = [
  'JANUARI',
  'FEBRUARI',
  'MARET',
  'APRIL',
  'MEI',
  'JUNI',
  'JULI',
  'AGUSTUS',
  'SEPTEMBER',
  'OKTOBER',
  'NOVEMBER',
  'DESEMBER',
];

/// The heading a draft sits under in the list: today, yesterday, the last
/// week, then its month and year. [sekarang] is injectable for tests.
String labelKelompok(DateTime? value, {DateTime? sekarang}) {
  if (value == null) return 'TANPA TANGGAL';
  final now = sekarang ?? DateTime.now();
  final hari = DateTime(value.year, value.month, value.day);
  final hariIni = DateTime(now.year, now.month, now.day);
  final selisih = hariIni.difference(hari).inDays;
  if (selisih <= 0) return 'HARI INI';
  if (selisih == 1) return 'KEMARIN';
  if (selisih < 7) return 'MINGGU INI';
  return '${_bulanPenuh[value.month - 1]} ${value.year}';
}
