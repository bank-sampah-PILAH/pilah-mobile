import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/utils/formatter/weight_formatter.dart';

void main() {
  group('WeightFormatter.formatKg', () {
    test('uses a comma decimal separator', () {
      expect(WeightFormatter.formatKg(2.5), '2,5');
      expect(WeightFormatter.formatKg(10.75), '10,75');
      expect(WeightFormatter.formatKg(5.2), '5,2');
    });

    test('trims trailing zeros down to a whole number', () {
      expect(WeightFormatter.formatKg(2.0), '2');
      expect(WeightFormatter.formatKg(2.300), '2,3');
      expect(WeightFormatter.formatKg(120.0), '120');
      expect(WeightFormatter.formatKg(15.10), '15,1');
    });

    test('rounds to a maximum of two decimals, half away from zero', () {
      // The exact acceptance-criteria example: 10.125 must land on "10,13".
      expect(WeightFormatter.formatKg(10.125), '10,13');
      expect(WeightFormatter.formatKg(17.123), '17,12');
      expect(WeightFormatter.formatKg(17.126), '17,13');
      expect(WeightFormatter.formatKg(3.456), '3,46');
    });

    test('keeps a significant leading zero in the fraction', () {
      expect(WeightFormatter.formatKg(5.05), '5,05');
      expect(WeightFormatter.formatKg(0.05), '0,05');
      expect(WeightFormatter.formatKg(0.5), '0,5');
    });

    test('accepts an int', () {
      expect(WeightFormatter.formatKg(2), '2');
      expect(WeightFormatter.formatKg(0), '0');
    });

    test('accepts a numeric String (dot-decimal, as the API sends)', () {
      expect(WeightFormatter.formatKg('2.3'), '2,3');
      expect(WeightFormatter.formatKg('17.123'), '17,12');
      expect(WeightFormatter.formatKg('120.000'), '120');
    });

    test('falls back to "0" for null or unparseable input', () {
      expect(WeightFormatter.formatKg(null), '0');
      expect(WeightFormatter.formatKg(''), '0');
      expect(WeightFormatter.formatKg('abc'), '0');
    });
  });
}
