import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/tile_health.dart';

void main() {
  test('stays healthy until the threshold is reached, then reports once', () {
    final health = TileHealth(ambang: 3);
    var pemberitahuan = 0;
    health.addListener(() => pemberitahuan++);

    health
      ..catatGalat()
      ..catatGalat();
    expect(health.buruk, isFalse);
    expect(pemberitahuan, 0);

    health.catatGalat();
    expect(health.buruk, isTrue);
    expect(pemberitahuan, 1);

    // Further failures while already degraded must not re-notify: the degraded
    // screens would rebuild on every tile of a broken map.
    health.catatGalat();
    expect(pemberitahuan, 1);
  });

  test('pulihkan clears the count so one bad tile cannot carry over', () {
    final health = TileHealth(ambang: 2);
    var pemberitahuan = 0;
    health.addListener(() => pemberitahuan++);

    health
      ..catatGalat()
      ..catatGalat()
      ..pulihkan();

    expect(health.buruk, isFalse);
    expect(pemberitahuan, 2);

    // The counter was reset, so a single new failure is not an outage.
    health.catatGalat();
    expect(health.buruk, isFalse);
  });
}
