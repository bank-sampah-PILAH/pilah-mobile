import 'package:test/test.dart';
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

  test('keeps a flow id that is a uuid of digits, not a phone number', () {
    expect(
        AnalyticsProps.sanitize(
            {'alur_id': '12345678-1234-4234-8234-123456789012'}),
        {'alur_id': '12345678-1234-4234-8234-123456789012'});
  });

  test('leaves out properties that are null', () {
    expect(AnalyticsProps.sanitize({'jumlah_item': null, 'langkah': 'item'}), {
      'langkah': 'item',
    });
  });

  test('refuses a property name that is not on the list', () {
    expect(
      () => AnalyticsProps.sanitize({'nama_nasabah': 'Siti'}),
      throwsA(isA<AssertionError>()),
    );
  });

  test('refuses personal data even under an allowed name', () {
    expect(
      () => AnalyticsProps.sanitize({'langkah': 'siti@example.com'}),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => AnalyticsProps.sanitize({'langkah': '+62 812-3456-7890'}),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => AnalyticsProps.sanitize({'langkah': '081234567890'}),
      throwsA(isA<AssertionError>()),
    );
  });

  test('refuses a value that is not a string, number or boolean', () {
    expect(
      () => AnalyticsProps.sanitize({'langkah': DateTime(2026)}),
      throwsA(isA<AssertionError>()),
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
      throwsA(isA<AssertionError>()),
    );
  });

  test('refuses a list that holds more than text', () {
    expect(
      () => AnalyticsProps.sanitize({
        'masalah': ['berat_nol', 3],
      }),
      throwsA(isA<AssertionError>()),
    );
  });

  group('cleanId', () {
    test('keeps an id that names nobody', () {
      expect(AnalyticsProps.cleanId('7c9819de-c44d-4fb3-acdf-b61d7d87174c'),
          '7c9819de-c44d-4fb3-acdf-b61d7d87174c');
      expect(AnalyticsProps.cleanId('42'), '42');
    });

    test('keeps a uuid made only of digits, which is not a phone number', () {
      // The demo and seed accounts have ids like this, and so can a real one.
      expect(AnalyticsProps.cleanId('00000000-0000-4000-8000-000000000011'),
          '00000000-0000-4000-8000-000000000011');
    });

    test('refuses an email address or a phone number as an id', () {
      expect(() => AnalyticsProps.cleanId('siti@example.com'),
          throwsA(isA<AssertionError>()));
      expect(() => AnalyticsProps.cleanId('081234567890'),
          throwsA(isA<AssertionError>()));
    });

    test('refuses an empty id', () {
      expect(() => AnalyticsProps.cleanId(''), throwsA(isA<AssertionError>()));
    });
  });
}
