import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/utils/formatter/setoran_subtotal.dart';

void main() {
  group('setoranSubtotal', () {
    test('rounds each item down to a whole rupiah, like the backend', () {
      expect(setoranSubtotal(1500, 0.001), 1);
      expect(setoranSubtotal(3000, 2.5), 7500);
      expect(setoranSubtotal(999, 0.002), 1);
    });

    test('is not thrown off by binary floating point', () {
      // 1000 * 0.29 is 289.99999999999994 as a double.
      expect(setoranSubtotal(1000, 0.29), 290);
      expect(setoranSubtotal(3000, 0.7), 2100);
    });

    test('is zero for no weight or no price', () {
      expect(setoranSubtotal(0, 2), 0);
      expect(setoranSubtotal(2000, 0), 0);
    });
  });
}
