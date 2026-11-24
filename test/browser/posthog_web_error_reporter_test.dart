@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:pilah_mobile/core/errors/posthog_web_error_reporter.dart';
import 'package:pilah_mobile/core/errors/web_exception_event_scrubber.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

final _fakeLibraryUrl = Uri.base.resolve('fake_posthog_library.js').toString();

Future<void> _loadFakeLibrary() async {
  final script = web.HTMLScriptElement()..src = _fakeLibraryUrl;
  final loaded = web.EventStreamProviders.loadEvent.forElement(script).first;
  web.document.head!.append(script);
  await loaded;
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

/// Declared `void` so it can be handed to JavaScript (`Never` cannot).
void _brokenLibraryCall() {
  throw StateError('library is broken');
}

void main() {
  tearDown(() {
    final all = web.document.scripts;
    for (var i = all.length - 1; i >= 0; i--) {
      final script = all.item(i)! as web.HTMLScriptElement;
      if (script.src == _fakeLibraryUrl) script.remove();
    }
    globalContext
      ..delete('posthog'.toJS)
      ..delete('__calls'.toJS)
      ..delete('__exceptions'.toJS);
  });

  group('PosthogWebErrorReporter', () {
    test('sends the error with a clean message and a stable name', () async {
      await _loadFakeLibrary();
      final reporter = PosthogWebErrorReporter();

      reporter.report(
        StateError('gagal untuk budi@example.com'),
        StackTrace.fromString('#0 main (app.dart:1:1)'),
        context: {'layar': 'setoran_baru'},
      );

      final sent = _exceptions().single;
      final error = sent[0]! as JSObject;
      expect(
        error.getProperty<JSString>('message'.toJS).toDart,
        'Bad state: gagal untuk [email]',
      );
      expect(error.getProperty<JSString>('name'.toJS).toDart, 'StateError');
      expect(
        error.getProperty<JSString>('stack'.toJS).toDart,
        contains('app.dart'),
      );
      expect(sent[1], {'layar': 'setoran_baru'});
    });

    test('says so to the cleaning step when nobody caught the error', () async {
      await _loadFakeLibrary();
      final reporter = PosthogWebErrorReporter();

      reporter.report(StateError('a'), StackTrace.current, handled: false);
      reporter.report(StateError('b'), StackTrace.current);

      final sent = _exceptions();
      expect(sent[0][1], {webNotHandledMarker: false});
      expect(sent[1][1], <Object?, Object?>{});
    });

    test('does nothing while the library is not there', () {
      final reporter = PosthogWebErrorReporter();

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
      final reporter = PosthogWebErrorReporter();

      expect(
        () => reporter.report(StateError('x'), StackTrace.current),
        returnsNormally,
      );
    });
  });
}
