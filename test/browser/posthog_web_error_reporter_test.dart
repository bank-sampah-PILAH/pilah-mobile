@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:pilah_mobile/core/errors/posthog_web_error_reporter.dart';
import 'package:pilah_mobile/core/errors/web_exception_event_scrubber.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

/// A stand-in for posthog-js that only records the errors it is handed.
const _fakeLibrary = '''
window.__exceptions = [];
window.posthog = {
  captureException: function (error, props) {
    window.__exceptions.push([error, props]);
  },
};
''';

/// Declared before `_loadFakeLibrary` so the tests read top to bottom.
Future<void> _loadFakeLibrary() async {
  final script = web.HTMLScriptElement()
    ..id = 'fake-posthog-library'
    ..text = _fakeLibrary;
  web.document.head!.append(script);
}

List<List<Object?>> _exceptions() {
  final all = globalContext.getProperty<JSArray<JSAny?>>('__exceptions'.toJS);
  return [
    for (final item in all.toDart)
      [
        (item! as JSArray<JSAny?>).toDart[0],
        (item as JSArray<JSAny?>).toDart[1].dartify(),
      ],
  ];
}

PosthogWebErrorReporter _reporter() => PosthogWebErrorReporter(
      typeName: (error) => 'NamedError',
      message: (error) => 'cleaned: ${error.runtimeType}',
    );

/// Declared `void` so it can be handed to JavaScript (`Never` cannot).
void _brokenLibraryCall() {
  throw StateError('library is broken');
}

void main() {
  tearDown(() {
    web.document.getElementById('fake-posthog-library')?.remove();
    globalContext
      ..delete('posthog'.toJS)
      ..delete('__exceptions'.toJS);
  });

  group('PosthogWebErrorReporter', () {
    test('sends the error under the name and message it is given', () async {
      await _loadFakeLibrary();
      final reporter = _reporter();

      reporter.report(
        StateError('x'),
        StackTrace.fromString('#0 main (app.dart:1:1)'),
        context: {'layar': 'setoran_baru'},
      );

      final sent = _exceptions().single;
      final error = sent[0]! as JSObject;
      expect(
        error.getProperty<JSString>('message'.toJS).toDart,
        'cleaned: StateError',
      );
      expect(error.getProperty<JSString>('name'.toJS).toDart, 'NamedError');
      expect(
        error.getProperty<JSString>('stack'.toJS).toDart,
        contains('app.dart'),
      );
      expect(sent[1], {'layar': 'setoran_baru'});
    });

    test('says so to the cleaning step when nobody caught the error', () async {
      await _loadFakeLibrary();
      final reporter = _reporter();

      reporter.report(StateError('a'), StackTrace.current, handled: false);
      reporter.report(StateError('b'), StackTrace.current);

      final sent = _exceptions();
      expect(sent[0][1], {webNotHandledMarker: false});
      expect(sent[1][1], <Object?, Object?>{});
    });

    test('does nothing while the library is not there', () {
      final reporter = _reporter();

      expect(
        () => reporter.report(StateError('x'), StackTrace.current),
        returnsNormally,
      );
    });

    test('never lets a failing library break the app', () async {
      await _loadFakeLibrary();
      globalContext
          .getProperty<JSObject>('posthog'.toJS)
          .setProperty('captureException'.toJS, _brokenLibraryCall.toJS);
      final reporter = _reporter();

      expect(
        () => reporter.report(StateError('x'), StackTrace.current),
        returnsNormally,
      );
    });
  });
}
