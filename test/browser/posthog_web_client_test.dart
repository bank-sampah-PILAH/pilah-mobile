@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:pilah_mobile/core/analytics/posthog_web_client.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

/// A tiny stand-in for PostHog's library, so tests never touch the network.
/// It only records how `posthog.init` was called.
final _fakeLibraryUrl = Uri.dataFromString(
  'window.posthog = { init: function (key, options) {'
  ' window.__initCalls = (window.__initCalls || 0) + 1;'
  ' window.__initArgs = [key, options]; } };',
  mimeType: 'text/javascript',
).toString();

List<web.HTMLScriptElement> _scriptsWithSource(String source) {
  final all = web.document.scripts;
  return [
    for (var i = 0; i < all.length; i++)
      if ((all.item(i)! as web.HTMLScriptElement).src == source)
        all.item(i)! as web.HTMLScriptElement,
  ];
}

void main() {
  tearDown(() {
    _scriptsWithSource(_fakeLibraryUrl).forEach((script) => script.remove());
    globalContext
      ..delete('posthog'.toJS)
      ..delete('__initCalls'.toJS)
      ..delete('__initArgs'.toJS);
  });

  test('adds no PostHog script until start is called', () {
    PosthogWebClient(
      apiKey: 'phc_test_key',
      host: 'https://us.i.posthog.com',
      libraryUrl: _fakeLibraryUrl,
    );

    expect(_scriptsWithSource(_fakeLibraryUrl), isEmpty);
  });

  test('start loads the library and initialises it for usage events only',
      () async {
    final client = PosthogWebClient(
      apiKey: 'phc_test_key',
      host: 'https://us.i.posthog.com',
      libraryUrl: _fakeLibraryUrl,
    );

    await client.start();

    expect(_scriptsWithSource(_fakeLibraryUrl), hasLength(1));
    final args = globalContext.getProperty<JSAny?>('__initArgs'.toJS).dartify()!
        as List<Object?>;
    expect(args[0], 'phc_test_key');
    expect(args[1], {
      'api_host': 'https://us.i.posthog.com',
      'disable_session_recording': true,
      'autocapture': false,
      'capture_pageview': false,
      'enable_heatmaps': false,
    });
  });

  test('the library address follows the PostHog host', () {
    expect(
      PosthogWebClient(apiKey: 'k', host: 'https://us.i.posthog.com')
          .libraryUrl,
      'https://us-assets.i.posthog.com/static/array.js',
    );
    expect(
      PosthogWebClient(apiKey: 'k', host: 'https://eu.i.posthog.com')
          .libraryUrl,
      'https://eu-assets.i.posthog.com/static/array.js',
    );
  });

  test('start fails instead of hanging when the library cannot be loaded',
      () async {
    final client = PosthogWebClient(
      apiKey: 'phc_test_key',
      host: 'https://us.i.posthog.com',
      // Nothing listens on port 1, so the script request is refused at once.
      libraryUrl: 'http://127.0.0.1:1/array.js',
    );

    await expectLater(
      client.start().timeout(const Duration(seconds: 10)),
      throwsA(isA<StateError>()),
    );
  });

  test('calling start twice loads and initialises the library once', () async {
    final client = PosthogWebClient(
      apiKey: 'phc_test_key',
      host: 'https://us.i.posthog.com',
      libraryUrl: _fakeLibraryUrl,
    );

    await client.start();
    await client.start();

    expect(_scriptsWithSource(_fakeLibraryUrl), hasLength(1));
    expect(
        globalContext.getProperty<JSNumber>('__initCalls'.toJS).toDartInt, 1);
  });
}
