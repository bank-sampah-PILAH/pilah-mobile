@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:pilah_mobile/core/analytics/posthog_web_client.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

/// Served next to this test by the test runner, so it has a normal address
/// (a `data:` script breaks the runner's coverage collection).
final _fakeLibraryUrl = Uri.base.resolve('fake_posthog_library.js').toString();
final _emptyLibraryUrl =
    Uri.base.resolve('empty_posthog_library.js').toString();

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
    _scriptsWithSource(_emptyLibraryUrl).forEach((script) => script.remove());
    globalContext
      ..delete('posthog'.toJS)
      ..delete('__initCalls'.toJS)
      ..delete('__initArgs'.toJS)
      ..delete('__emptyLibraryLoaded'.toJS);
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

  test('start fails instead of hanging when the library never answers',
      () async {
    // A new address each time, so the browser cannot answer from its cache.
    final uncachedUrl =
        '$_fakeLibraryUrl?t=${DateTime.now().microsecondsSinceEpoch}';
    final client = PosthogWebClient(
      apiKey: 'phc_test_key',
      host: 'https://us.i.posthog.com',
      libraryUrl: uncachedUrl,
      // Too short for any script to arrive, like a blackholed CDN.
      loadTimeout: Duration.zero,
    );

    await expectLater(
      client.start(),
      throwsA(isA<StateError>()
          .having((e) => e.message, 'message', contains('Timed out'))),
    );
    expect(_scriptsWithSource(uncachedUrl), isEmpty,
        reason: 'the script that never answered is taken out again');
  });

  test('a failed start is tried again by the next start, not remembered',
      () async {
    final client = PosthogWebClient(
      apiKey: 'phc_test_key',
      host: 'https://us.i.posthog.com',
      libraryUrl: 'http://127.0.0.1:1/array.js',
    );

    Object? first;
    Object? second;
    await client.start().catchError((Object e) => first = e);
    await client.start().catchError((Object e) => second = e);

    expect(first, isA<StateError>());
    expect(second, isA<StateError>());
    expect(identical(first, second), isFalse,
        reason: 'the second start made its own attempt');
  });

  test('a library that loads without defining posthog is a clear error',
      () async {
    final client = PosthogWebClient(
      apiKey: 'phc_test_key',
      host: 'https://us.i.posthog.com',
      libraryUrl: _emptyLibraryUrl,
    );

    await expectLater(
      client.start(),
      throwsA(isA<StateError>()
          .having((e) => e.message, 'message', contains('did not define'))),
    );
  });
}
