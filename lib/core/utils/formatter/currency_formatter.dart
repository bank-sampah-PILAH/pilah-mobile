abstract final class CurrencyFormatter {
  static String formatRupiah(int value) {
    final digits = value.toString();
    var result = '';
    var count = 0;
    for (var i = digits.length - 1; i >= 0; i--) {
      result = digits[i] + result;
      count++;
      if (count % 3 == 0 && i != 0) result = '.$result';
    }
    return 'Rp $result';
  }
}
