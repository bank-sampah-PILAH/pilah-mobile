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
}
