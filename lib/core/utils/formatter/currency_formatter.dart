/// The one place Rupiah amounts are formatted: `.` between thousands, no
/// decimals, matching the backend (`Rp 1.500`).
abstract final class CurrencyFormatter {
  /// `1500` -> `1.500`, `-1500` -> `-1.500`. No currency prefix.
  static String formatNumber(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return '${value < 0 ? '-' : ''}$buffer';
  }

  /// `3500` -> `Rp 3.500`, `-3500` -> `Rp -3.500`.
  static String formatRupiah(int value) {
    final sign = value < 0 ? '-' : '';
    return 'Rp $sign${formatNumber(value.abs())}';
  }

  /// An amount held in sen: `333399` -> `Rp 3.333,99`, `350000` -> `Rp 3.500`.
  static String formatRupiahSen(int sen) {
    final sign = sen < 0 ? '-' : '';
    final rupiah = 'Rp $sign${formatNumber(sen.abs() ~/ 100)}';
    final sisa = sen.abs() % 100;
    return sisa == 0 ? rupiah : '$rupiah,${sisa.toString().padLeft(2, '0')}';
  }

  /// Formats a number as the backend sends it (int, double or numeric string),
  /// rounded to whole rupiah. Missing or unparseable values read as `Rp 0`.
  static String formatRupiahValue(Object? value) {
    final amount = double.tryParse(value?.toString() ?? '') ?? 0;
    return formatRupiah(amount.round());
  }
}
