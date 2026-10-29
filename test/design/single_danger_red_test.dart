import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// "Danger" is one red, `AppColors.danger`, with `AppColors.dangerLight` as its
/// tint. Two different reds (and a tint that failed contrast) used to be copied
/// into a dozen screens.
void main() {
  test('only AppColors defines the danger red and its tint', () {
    const retired = ['0XFFDC2626', '0XFFC62828', '0XFFFEF2F2'];
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path == 'lib/design/constants/colors.dart') continue;
      final source = entity.readAsStringSync().toUpperCase();
      if (retired.any(source.contains)) offenders.add(path);
    }

    expect(offenders, isEmpty,
        reason: 'Use AppColors.danger / AppColors.dangerLight instead.');
  });
}
