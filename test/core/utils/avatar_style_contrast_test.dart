import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/utils/avatar_style.dart';

import '../../support/contrast.dart';

/// Initials sit on a tinted tile, so every pair of the avatar palette must be
/// readable (WCAG AA, 4.5:1 for normal-size text).
void main() {
  test('every avatar colour pair keeps its initials readable', () {
    final pairs = <(Color, Color)>{
      for (var i = 0; i < 400; i++) avatarPaletteFor('Nasabah $i'),
    };

    expect(pairs.length, greaterThan(1), reason: 'sampled the whole palette');
    for (final (background, text) in pairs) {
      expect(contrast(text, background), greaterThanOrEqualTo(4.5),
          reason: '$text on $background');
    }
  });
}
