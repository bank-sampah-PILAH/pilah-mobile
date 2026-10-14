import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Raw colours that were folded into `AppColors` tokens. Screens must use the
/// token, so the same grey or amber is not copied (and slightly changed) from
/// file to file again.
const _retired = <String, List<String>>{
  'neutral greys': [
    'F9FAFB', 'F3F4F6', 'F5F5F5', 'F0F2F0', //
    'EEEEEE', 'E5E7EB', 'D1D5DB', //
    '6B7280', '4B5563', '374151', '59665C',
  ],
  'ambers and oranges': [
    'FEF3C7', 'FFF8E1', 'FFF4DE', 'FFF8D6', //
    'B26A00', 'D97706', '9A6400', '8A5A00', //
    'B45309', '92400E', 'D4A017', 'D4A843', 'F59E0B',
  ],
  'green tints and dark greens': [
    'F0FDF4', 'E8F5E9', 'DCFCE7', 'EAF5EC', //
    '166534', '2F6B45',
  ],
  'red tints and dark reds': [
    'FDECEC', 'FEE2E2', 'FDECEA', 'FECACA', //
    '991B1B', 'BA1A1A', '9B3D3D',
  ],
};

void main() {
  for (final group in _retired.entries) {
    test('no screen defines its own ${group.key}', () {
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path == 'lib/design/constants/colors.dart') continue;
        final source = entity.readAsStringSync().toUpperCase();
        for (final hex in group.value) {
          if (source.contains('0XFF$hex')) {
            offenders.add('${entity.path}: $hex');
          }
        }
      }

      expect(offenders, isEmpty, reason: 'Use the AppColors token instead.');
    });
  }
}
