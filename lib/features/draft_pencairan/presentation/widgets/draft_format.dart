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
