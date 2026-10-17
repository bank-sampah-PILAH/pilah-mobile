import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/utils/formatter/date_time_formatter.dart';

void main() {
  group('isoDenganOffset', () {
    test('writes the UTC offset instead of leaving the time ambiguous', () {
      expect(
        isoDenganOffset(DateTime.utc(2026, 10, 14, 17, 0, 5)),
        '2026-10-14T17:00:05+00:00',
      );
    });

    test('keeps a local time on the same instant once parsed back', () {
      final tengahMalam = DateTime(2026, 10, 15);

      final iso = isoDenganOffset(tengahMalam);

      expect(iso, matches(RegExp(r'^2026-10-15T00:00:00[+-]\d\d:\d\d$')));
      expect(DateTime.parse(iso).isAtSameMomentAs(tengahMalam), isTrue);
    });
  });
}
