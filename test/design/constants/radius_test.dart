import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/constants/radius.dart';

void main() {
  test('the radius scale is 4, 8, 12, 16 and 24', () {
    expect(
      [
        AppRadius.xs,
        AppRadius.sm,
        AppRadius.md,
        AppRadius.lg,
        AppRadius.xl,
      ],
      [4, 8, 12, 16, 24],
    );
  });

  test('each step is larger than the one before', () {
    final scale = [
      AppRadius.xs,
      AppRadius.sm,
      AppRadius.md,
      AppRadius.lg,
      AppRadius.xl,
      AppRadius.pill,
    ];
    for (var i = 1; i < scale.length; i++) {
      expect(scale[i], greaterThan(scale[i - 1]));
    }
  });

  test('a pill is rounder than any box can be', () {
    expect(AppRadius.pill, greaterThanOrEqualTo(100));
  });
}
