import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/errors/exception_event_scrubber.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

PostHogEvent _exception(Object? list) => PostHogEvent(
      event: r'$exception',
      properties: {if (list != null) r'$exception_list': list},
    );

void main() {
  group('scrubExceptionEvent', () {
    test('replaces the message of every exception with its type', () {
      final event = _exception([
        {
          'type': 'StateError',
          'value': 'Budi Santoso menyetor Rp 50.000 di Jl. Melati 5',
        },
        {'type': 'FormatException', 'value': 'nomor 081234567890 untuk Siti'},
      ]);

      final out = scrubExceptionEvent(event)!;

      final list = out.properties![r'$exception_list']! as List;
      expect((list[0] as Map)['value'], 'StateError');
      expect((list[1] as Map)['value'], 'FormatException');
      expect((list[0] as Map)['type'], 'StateError');
    });

    test('drops an exception that has no type to fall back on', () {
      final event = _exception([
        {'value': 'Budi Santoso menyetor Rp 50.000'},
      ]);

      expect(scrubExceptionEvent(event), isNull);
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
