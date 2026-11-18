import 'package:flutter_test/flutter_test.dart';

import '../support/design_ratchet.dart';

/// "Danger" is one red, `AppColors.danger`, with `AppColors.dangerLight` as its
/// tint. Two different reds (and a tint that failed contrast) used to be copied
/// into a dozen screens.
void main() {
  test('only AppColors defines the danger red and its tint', () {
    const retired = ['0XFFDC2626', '0XFFC62828', '0XFFFEF2F2'];
    final offenders = <String>[];
    for (final source in designSources()) {
      final path = source.path;
      if (path == 'lib/design/constants/colors.dart') continue;
      final text = source.read().toUpperCase();
      if (retired.any(text.contains)) offenders.add(path);
    }

    expect(offenders, isEmpty,
        reason: 'Use AppColors.danger / AppColors.dangerLight instead.');
  });
}
