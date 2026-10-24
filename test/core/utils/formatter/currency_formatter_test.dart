import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/utils/formatter/currency_formatter.dart';

void main() {
  group('formatNumber', () {
    test('groups thousands with a dot', () {
      expect(CurrencyFormatter.formatNumber(0), '0');
      expect(CurrencyFormatter.formatNumber(999), '999');
      expect(CurrencyFormatter.formatNumber(1500), '1.500');
      expect(CurrencyFormatter.formatNumber(1234567), '1.234.567');
    });

    test('keeps the sign in front of the digits', () {
      expect(CurrencyFormatter.formatNumber(-1500), '-1.500');
      expect(CurrencyFormatter.formatNumber(-999), '-999');
    });
  });

  group('formatRupiah', () {
    test('prefixes Rp', () {
      expect(CurrencyFormatter.formatRupiah(3500), 'Rp 3.500');
      expect(CurrencyFormatter.formatRupiah(0), 'Rp 0');
    });

    test('puts the minus after the prefix', () {
      expect(CurrencyFormatter.formatRupiah(-3500), 'Rp -3.500');
    });
  });

  group('formatRupiahSen (amounts held in sen)', () {
    test('shows sen after a comma, and drops them when there are none', () {
      expect(CurrencyFormatter.formatRupiahSen(333399), 'Rp 3.333,99');
      expect(CurrencyFormatter.formatRupiahSen(350005), 'Rp 3.500,05');
      expect(CurrencyFormatter.formatRupiahSen(350000), 'Rp 3.500');
      expect(CurrencyFormatter.formatRupiahSen(0), 'Rp 0');
    });

    test('keeps the sign of an amount under one rupiah', () {
      expect(CurrencyFormatter.formatRupiahSen(-50), 'Rp -0,50');
      expect(CurrencyFormatter.formatRupiahSen(-350000), 'Rp -3.500');
    });
  });

  group('formatRupiahValue (backend numbers)', () {
    test('accepts ints, doubles and numeric strings, rounding to rupiah', () {
      expect(CurrencyFormatter.formatRupiahValue(1500), 'Rp 1.500');
      expect(CurrencyFormatter.formatRupiahValue('1500.00'), 'Rp 1.500');
      expect(CurrencyFormatter.formatRupiahValue(1499.6), 'Rp 1.500');
      expect(CurrencyFormatter.formatRupiahValue('-2500'), 'Rp -2.500');
    });

    test('treats missing or unparseable values as zero', () {
      expect(CurrencyFormatter.formatRupiahValue(null), 'Rp 0');
      expect(CurrencyFormatter.formatRupiahValue('abc'), 'Rp 0');
    });
  });
}
