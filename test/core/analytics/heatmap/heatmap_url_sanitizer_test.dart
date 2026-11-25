import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/analytics/heatmap/heatmap_url_sanitizer.dart';

void main() {
  const origin = 'https://app.example.com';
  final sanitizer = HeatmapUrlSanitizer(const [
    '/dashboard',
    '/nasabah',
    '/nasabah/new',
    '/nasabah/:id',
    '/nasabah/:id/transaksi/:transaksiId',
  ]);

  test('an id in the address is replaced by its route pattern', () {
    expect(
      sanitizer.sanitize('$origin/#/nasabah/8f14e45f-ceea-467f'),
      '$origin/#/nasabah/:id',
    );
  });

  test('a fixed route keeps its name and loses its query', () {
    expect(
      sanitizer.sanitize('$origin/#/dashboard?periode=7&q=budi'),
      '$origin/#/dashboard',
    );
  });

  test('a route that is not in the app is dropped, not sent as it is', () {
    expect(sanitizer.sanitize('$origin/#/rahasia/budi-santoso'), isNull);
    expect(sanitizer.sanitize('$origin/#/nasabah/1/lain'), isNull);
  });

  test('a fixed route beats a pattern with a value in its place', () {
    final reversed =
        HeatmapUrlSanitizer(const ['/nasabah/:id', '/nasabah/new']);

    expect(reversed.sanitize('$origin/#/nasabah/new'), '$origin/#/nasabah/new');
  });

  test('every value of a longer route is replaced', () {
    expect(
      sanitizer.sanitize('$origin/#/nasabah/12/transaksi/99'),
      '$origin/#/nasabah/:id/transaksi/:transaksiId',
    );
  });
}
