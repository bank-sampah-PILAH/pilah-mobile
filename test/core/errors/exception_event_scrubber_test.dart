import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/errors/exception_event_scrubber.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

PostHogEvent _exception(Object? list) => PostHogEvent(
      event: r'$exception',
      properties: {if (list != null) r'$exception_list': list},
    );

void main() {
  group('scrubExceptionEvent', () {
    test('cleans the message of every exception in the list', () {
      final event = _exception([
        {'type': 'StateError', 'value': 'gagal untuk budi@example.com'},
        {'type': 'FormatException', 'value': 'nomor 081234567890'},
      ]);

      final out = scrubExceptionEvent(event)!;

      final list = out.properties![r'$exception_list']! as List;
      expect((list[0] as Map)['value'], 'gagal untuk [email]');
      expect((list[1] as Map)['value'], 'nomor [angka]');
      expect((list[0] as Map)['type'], 'StateError');
    });

    test('leaves every other event alone', () {
      final event = PostHogEvent(
        event: 'app_dibuka',
        properties: {'note': 'hubungi budi@example.com'},
      );

      expect(scrubExceptionEvent(event)!.properties!['note'],
          'hubungi budi@example.com');
    });

    test('drops an exception event it cannot read instead of sending it', () {
      expect(scrubExceptionEvent(_exception('not a list')), isNull);
      expect(scrubExceptionEvent(_exception(null)), isNull);
    });
  });
}
