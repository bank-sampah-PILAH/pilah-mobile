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

/// What the fake library was asked to do, in order. Empty if it never loaded.
List<String> _libraryCalls() {
  final calls = globalContext.getProperty<JSAny?>('__calls'.toJS).dartify();
  return calls == null ? [] : (calls as List<Object?>).cast<String>();
}

/// Each event the fake library was asked to capture, as `[name, properties]`.
List<List<Object?>> _captures() {
  final captures =
      globalContext.getProperty<JSAny?>('__captures'.toJS).dartify();
  return captures == null
      ? []
      : (captures as List<Object?>).map((e) => e as List<Object?>).toList();
}

List<Object?> _identified() {
  final ids = globalContext.getProperty<JSAny?>('__identified'.toJS).dartify();
  return ids == null ? [] : (ids as List<Object?>);
}

List<Map<Object?, Object?>> _registered() {
  final all = globalContext.getProperty<JSAny?>('__registered'.toJS).dartify();
  return all == null
      ? []
      : (all as List<Object?>).map((e) => e as Map<Object?, Object?>).toList();
}

PosthogWebClient _client({String? environment}) => PosthogWebClient(
      apiKey: 'phc_test_key',
      host: 'https://us.i.posthog.com',
      libraryUrl: _fakeLibraryUrl,
      environment: environment,
    );

void main() {
  tearDown(() {
    _scriptsWithSource(_fakeLibraryUrl).forEach((script) => script.remove());
    _scriptsWithSource(_emptyLibraryUrl).forEach((script) => script.remove());
    globalContext
      ..delete('posthog'.toJS)
      ..delete('__calls'.toJS)
      ..delete('__captures'.toJS)
      ..delete('__identified'.toJS)
      ..delete('__registered'.toJS)
      ..delete('__initCalls'.toJS)
      ..delete('__initArgs'.toJS)
      ..delete('__optInOptions'.toJS)
      ..delete('__emptyLibraryLoaded'.toJS);
  });

  test('is available, so the consent dialog may be shown', () {
    expect(_client().isAvailable, isTrue);
  });

  test('stop before start loads nothing and touches nothing', () async {
    await _client().stop();

    expect(_scriptsWithSource(_fakeLibraryUrl), isEmpty);
    expect(_libraryCalls(), isEmpty);
  });

  test('stop after start opts out of capturing', () async {
    final client = _client();
    await client.start();

    await client.stop();

    expect(_libraryCalls(), [
      'init',
      'opt_in_capturing',
      'register',
      'opt_out_capturing',
    ]);
  });

  test('start after stop opts back in without loading the library again',
      () async {
    final client = _client();
    await client.start();
    await client.stop();

    await client.start();

    expect(_scriptsWithSource(_fakeLibraryUrl), hasLength(1));
    expect(_libraryCalls(), [
      'init',
      'opt_in_capturing',
      'register',
      'opt_out_capturing',
      'opt_in_capturing',
    ]);
  });

  test('events and screens sent before start go nowhere', () {
    final client = _client();

    client.capture('setoran_disimpan', {'jumlah_item': 2});
    client.screen('dashboard');

    expect(_scriptsWithSource(_fakeLibraryUrl), isEmpty);
    expect(_captures(), isEmpty);
  });

  test('capture passes the event and its cleaned properties on', () async {
    final client = _client();
    await client.start();

    client.capture('setoran_disimpan', {'jumlah_item': 2, 'durasi_detik': 30});

    expect(_captures(), [
      [
        'setoran_disimpan',
        {'jumlah_item': 2, 'durasi_detik': 30},
      ],
    ]);
  });

  test('screen sends a screen event named after the screen', () async {
    final client = _client();
    await client.start();

    client.screen('nasabah');

    expect(_captures(), [
      [
        r'$screen',
        {r'$screen_name': 'nasabah'},
      ],
    ]);
  });

  test('a screen can say which screen it follows and for how long', () async {
    final client = _client();
    await client.start();

    client.screen('nasabah', {
      'layar_sebelumnya': 'dashboard',
      'durasi_layar_sebelumnya_detik': 12,
    });

    expect(_captures(), [
      [
        r'$screen',
        {
          r'$screen_name': 'nasabah',
          'layar_sebelumnya': 'dashboard',
          'durasi_layar_sebelumnya_detik': 12,
        },
      ],
    ]);
  });

  test('nothing is sent after stop, and sending resumes after start', () async {
    final client = _client();
    await client.start();
    await client.stop();

    client.capture('setoran_disimpan', {'jumlah_item': 1});
    expect(_captures(), isEmpty);

    await client.start();
    client.capture('setoran_disimpan', {'jumlah_item': 1});
    expect(_captures(), hasLength(1));
  });

  test('identity sent before start goes nowhere and loads nothing', () {
    final client = _client();

    client.identify('user-1');
    client.register({'peran': 'pengelola'});
    client.reset();

    expect(_scriptsWithSource(_fakeLibraryUrl), isEmpty);
    expect(_libraryCalls(), isEmpty);
  });

  test('identify tells the library who the user is', () async {
    final client = _client();
    await client.start();

    client.identify('7c9819de-c44d-4fb3-acdf-b61d7d87174c');

    expect(_identified(), ['7c9819de-c44d-4fb3-acdf-b61d7d87174c']);
  });

  test('register passes cleaned properties for every event', () async {
    final client = _client();
    await client.start();

    client.register({'peran': 'pengelola'});

    expect(_registered().last, {'peran': 'pengelola'});
  });

  test('reset forgets the user, even after analytics was stopped', () async {
    final client = _client();
    await client.start();
    client.identify('user-1');
    await client.stop();

    client.reset();

    expect(_libraryCalls(), contains('reset'));
  });

  test('identify does nothing after stop', () async {
    final client = _client();
    await client.start();
    await client.stop();

    client.identify('user-1');

    expect(_identified(), isEmpty);
  });

  test('the library is told the environment, the platform and the screen size',
      () async {
    final client = _client(environment: 'staging');

    await client.start();

    final registered = _registered().single;
    expect(registered['environment'], 'staging');
    expect(registered['platform'], 'web');
    expect(registered['kelas_layar'], isIn(['ponsel', 'tablet', 'desktop']));
  });

  test('signing out and in again tells the library where this runs once more',
      () async {
    final client = _client(environment: 'staging');
    await client.start();
    await client.stop();
    client.reset();

    await client.start();

    // posthog-js forgets what it was told when it is reset, so a start that
    // only opts back in would send every event without these.
    final all = _registered();
    expect(all, hasLength(2));
    expect(all.last['environment'], 'staging');
    expect(all.last['platform'], 'web');
    expect(all.last['kelas_layar'], isIn(['ponsel', 'tablet', 'desktop']));
  });

  test('without an environment only the platform and screen size are told',
      () async {
    final client = _client();

    await client.start();

    expect(_registered().single.keys, isNot(contains('environment')));
    expect(_registered().single['platform'], 'web');
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
      // posthog-js adds the address and referrer to every event by itself;
      // a route can carry an id, so none of them may leave the app.
      'property_denylist': [
        r'$current_url',
        r'$pathname',
        r'$referrer',
        r'$referring_domain',
        r'$host',
        r'$initial_current_url',
        r'$initial_pathname',
        r'$initial_referrer',
        r'$initial_referring_domain',
        r'$initial_host',
      ],
      // posthog-js builds the `$initial_*` person properties from storage and
      // sends them as `$set_once`, where the denylist above does not reach. Not
      // saving the referrer and the campaign parameters keeps it from storing
      // the first visit's address at all.
      'save_referrer': false,
      'save_campaign_params': false,
      'capture_performance': true,
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
    // The empty library: taking the script out again does not cancel a request
    // already sent, so the script may still run during a later test, and it
    // must not define `posthog` then.
    final uncachedUrl =
        '$_emptyLibraryUrl?t=${DateTime.now().microsecondsSinceEpoch}';
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

  test('start opts in even when an earlier visit opted out', () async {
    // PostHog keeps an opt-out across page reloads. A fresh client has not
    // stopped anything itself, but the pengurus agreed again, so it opts in.
    final client = _client();

    await client.start();

    expect(_libraryCalls(), ['init', 'opt_in_capturing', 'register']);
  });

  test('opting in does not make PostHog send an event of its own', () async {
    // By default opt_in_capturing sends a `$opt_in` event, which would reach
    // PostHog without passing the sanitizer.
    final client = _client();

    await client.start();
    await client.stop();
    await client.start();

    final options = globalContext
        .getProperty<JSAny?>('__optInOptions'.toJS)
        .dartify()! as List<Object?>;
    expect(options, hasLength(2));
    expect(options, everyElement({'captureEventName': false}));
  });

  test('a stop that comes while the library is still loading wins', () async {
    final client = _client();

    final starting = client.start();
    final stopping = client.stop();
    await starting;
    await stopping;
    client.capture('app_dibuka');
    client.screen('dashboard');

    expect(_libraryCalls(), isNot(contains('capture')),
        reason: 'the pengurus withdrew before the library finished loading');
  });

  test('two starts at the same time still leave the client live', () async {
    // Consent and the saved choice can both start the client while the library
    // is loading. The later start must not leave the earlier caller's events
    // dropped.
    final client = _client();

    final first = client.start();
    final second = client.start();
    await first;
    client.capture('app_dibuka');
    await second;

    expect(_libraryCalls(), contains('capture'),
        reason: 'the caller of the first start was told the client is running');
  });

  group('when the library never loaded', () {
    PosthogWebClient failingClient() => PosthogWebClient(
          apiKey: 'phc_test_key',
          host: 'https://us.i.posthog.com',
          // Nothing listens on port 1, so the script request is refused.
          libraryUrl: 'http://127.0.0.1:1/array.js',
        );

    test('forgetting the user does nothing instead of throwing', () async {
      final client = failingClient();
      await client.start().catchError((Object _) {});

      expect(client.reset, returnsNormally);
    });

    test('stopping does nothing instead of throwing, so a withdrawal is kept',
        () async {
      final client = failingClient();
      await client.start().catchError((Object _) {});

      await expectLater(client.stop(), completes);
    });

    test('stopping while the library is still failing to load is kept too',
        () async {
      final client = failingClient();
      final started = client.start().then<void>((_) {}, onError: (Object _) {});

      await expectLater(client.stop(), completes);
      await started;
    });
  });

  test('the screen class follows the width of the window', () {
    expect(PosthogWebClient.screenClassFor(599), 'ponsel');
    expect(PosthogWebClient.screenClassFor(600), 'tablet');
    expect(PosthogWebClient.screenClassFor(1023), 'tablet');
    expect(PosthogWebClient.screenClassFor(1024), 'desktop');
    expect(PosthogWebClient.screenClassFor(0), 'ponsel');
    expect(PosthogWebClient.screenClassFor(1023.9), 'tablet');
    expect(PosthogWebClient.screenClassFor(5000), 'desktop');
  });
}
