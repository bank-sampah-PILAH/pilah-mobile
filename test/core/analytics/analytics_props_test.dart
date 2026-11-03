import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/analytics/analytics_props.dart';

void main() {
  test('keeps allowed properties as they are', () {
    final clean = AnalyticsProps.sanitize({
      'jumlah_item': 3,
      'durasi_detik': 42.5,
      'ada_hasil': true,
      'langkah': 'item',
    });

    expect(clean, {
      'jumlah_item': 3,
      'durasi_detik': 42.5,
      'ada_hasil': true,
      'langkah': 'item',
    });
  });

  test('leaves out properties that are null', () {
    expect(AnalyticsProps.sanitize({'jumlah_item': null, 'langkah': 'item'}), {
      'langkah': 'item',
    });
  });

  test('refuses a property name that is not on the list', () {
    expect(
      () => AnalyticsProps.sanitize({'nama_nasabah': 'Siti'}),
      throwsAssertionError,
    );
  });

  test('refuses personal data even under an allowed name', () {
    expect(
      () => AnalyticsProps.sanitize({'langkah': 'siti@example.com'}),
      throwsAssertionError,
    );
    expect(
      () => AnalyticsProps.sanitize({'langkah': '+62 812-3456-7890'}),
      throwsAssertionError,
    );
    expect(
      () => AnalyticsProps.sanitize({'langkah': '081234567890'}),
      throwsAssertionError,
    );
  });

  test('refuses a value that is not a string, number or boolean', () {
    expect(
      () => AnalyticsProps.sanitize({'langkah': DateTime(2026)}),
      throwsAssertionError,
    );
  });

  test('allows a list of names, such as validation problems', () {
    expect(
      AnalyticsProps.sanitize({
        'masalah': ['berat_nol', 'belum_ada_item'],
      }),
      {
        'masalah': ['berat_nol', 'belum_ada_item'],
      },
    );
  });

  test('never allows money, balances, names or search text', () {
    for (final name in [
      'nominal',
      'saldo',
      'harga',
      'total',
      'nama',
      'email',
      'telepon',
      'kata_pencarian',
      'nasabah_id',
    ]) {
      expect(AnalyticsProps.allowed, isNot(contains(name)), reason: name);
    }
  });

  test('refuses personal data inside a list', () {
    expect(
      () => AnalyticsProps.sanitize({
        'masalah': ['berat_nol', 'siti@example.com'],
      }),
      throwsAssertionError,
    );
  });

  test('refuses a list that holds more than text', () {
    expect(
      () => AnalyticsProps.sanitize({
        'masalah': ['berat_nol', 3],
      }),
      throwsAssertionError,
    );
  });
}
