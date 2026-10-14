import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/constants/colors.dart';

/// The app has one primary green, `AppColors.greenDark`. A second copy of it
/// used to live in a dozen files; this keeps screens from drifting apart again.
void main() {
  test('the primary green is the emerald that matches the logo', () {
    expect(AppColors.greenDark, const Color(0xFF006D44));
  });

  test('only AppColors defines the primary green', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path == 'lib/design/constants/colors.dart') continue;
      if (entity.readAsStringSync().toUpperCase().contains('0XFF006D44')) {
        offenders.add(entity.path);
      }
    }

    expect(offenders, isEmpty, reason: 'Use AppColors.greenDark instead.');
  });
}
