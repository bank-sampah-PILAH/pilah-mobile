@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/errors/error_reporter_factory.dart';
import 'package:pilah_mobile/core/errors/web_exception_event_scrubber.dart';
import 'package:web/web.dart' as web;

/// What a pengurus must never see leave the app inside an error: names,
/// amounts, addresses and numbers that were in the data being handled.
const _personal = [
  'Budi Santoso',
  'Rp 50.000',
  'Jl. Melati 5',
  '081234567890',
];

String get _message =>
    'Gagal menyimpan setoran ${_personal[1]} untuk ${_personal[0]} '
    'di ${_personal[2]} (${_personal[3]})';

/// A stand-in for posthog-js that records what it is handed.
const _fakeLibrary = '''
window.__exceptions = [];
window.posthog = {
  captureException: function (error, props) {
    window.__exceptions.push([error, props]);
  },
};
''';

void main() {
  setUp(() {
    web.document.head!.append(web.HTMLScriptElement()
      ..id = 'fake-posthog-library'
      ..text = _fakeLibrary);
  });

  tearDown(() {
    web.document.getElementById('fake-posthog-library')?.remove();
    globalContext
      ..delete('posthog'.toJS)
      ..delete('__exceptions'.toJS);
  });

  JSObject sentError() {
    final all = globalContext.getProperty<JSArray<JSAny?>>('__exceptions'.toJS);
    return (all.toDart.single! as JSArray<JSAny?>).toDart[0]! as JSObject;
  }

  group('what the real web reporter sends for an error full of personal data',
      () {
    test('is only the type, in the name and in the message', () {
      createPlatformErrorReporter().report(
        StateError(_message),
        StackTrace.fromString('#0 main (app.dart:1:1)'),
      );

      final error = sentError();
      expect(error.getProperty<JSString>('message'.toJS).toDart, 'StateError');
      expect(error.getProperty<JSString>('name'.toJS).toDart, 'StateError');
      for (final text in _personal) {
        expect(error.dartify().toString(), isNot(contains(text)));
        expect(error.getProperty<JSString>('stack'.toJS).toDart,
            isNot(contains(text)));
      }
    });

    test('is also only the type for a FormatException that quotes its input',
        () {
      createPlatformErrorReporter().report(
        FormatException('tidak bisa dibaca', _personal[0]),
        StackTrace.current,
      );

      final message = sentError().getProperty<JSString>('message'.toJS).toDart;
      expect(message, 'FormatException');
    });
  });

  group('what the before_send step lets through', () {
    test('an exception event keeps its type and loses its message', () {
      final out = scrubWebExceptionEvent({
        'event': r'$exception',
        'properties': {
          r'$exception_list': [
            {'type': 'StateError', 'value': _message},
          ],
        },
      }.jsify())! as JSObject;

      final dart = out.dartify()! as Map;
      final text = dart.toString();
      for (final personal in _personal) {
        expect(text, isNot(contains(personal)));
      }
      final entry = ((dart['properties']! as Map)[r'$exception_list']! as List)
          .single as Map;
      expect(entry['value'], 'StateError');
    });
  });
}
