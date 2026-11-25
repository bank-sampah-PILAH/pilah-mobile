@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:pilah_mobile/core/analytics/heatmap/heatmap_url_sanitizer.dart';
import 'package:pilah_mobile/core/analytics/heatmap/posthog_web_heatmap.dart';
import 'package:pilah_mobile/core/analytics/heatmap/scroll_position_source.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

/// Where the page is scrolled, as the test says it is.
class _Scroll implements ScrollPositionSource {
  @override
  double tapOffset = 120;

  @override
  double liveOffset = 480;
}

/// The part of posthog-js the heatmap reads: a scroll manager whose methods the
/// app may replace.
JSObject _fakePosthog() {
  final manager = JSObject()
    ..setProperty('scrollY'.toJS, (() => 0.toJS).toJS)
    ..setProperty('scrollX'.toJS, (() => 7.toJS).toJS);
  return JSObject()..setProperty('scrollManager'.toJS, manager);
}

double _scrollY(JSObject posthog) => posthog
    .getProperty<JSObject>('scrollManager'.toJS)
    .callMethod<JSNumber>('scrollY'.toJS)
    .toDartDouble;

PosthogWebHeatmap _heatmap(_Scroll scroll) => PosthogWebHeatmap(
      scroll: scroll,
      urls: HeatmapUrlSanitizer(const ['/nasabah/:id']),
    );

void main() {
  late PosthogWebHeatmap heatmap;

  tearDown(() => heatmap.dispose());

  test('away from a click, the page is where the main list is scrolled to', () {
    final posthog = _fakePosthog();
    heatmap = _heatmap(_Scroll())..install(posthog);

    expect(_scrollY(posthog), 480);
  });

  test(
      'while a click is handled, the page is where the tapped list is scrolled',
      () async {
    final posthog = _fakePosthog();
    heatmap = _heatmap(_Scroll())..install(posthog);
    double? seenByLibrary;
    // posthog-js listens on the document; this runs there, after the window.
    final listener = ((web.Event _) => seenByLibrary = _scrollY(posthog)).toJS;
    web.document.addEventListener('click', listener);
    addTearDown(() => web.document.removeEventListener('click', listener));

    web.document.body!.dispatchEvent(
        web.MouseEvent('click', web.MouseEventInit(bubbles: true)));
    await Future<void>.delayed(Duration.zero);

    expect(seenByLibrary, 120);
    expect(_scrollY(posthog), 480);
  });

  test('the page is never scrolled sideways', () {
    final posthog = _fakePosthog();
    heatmap = _heatmap(_Scroll())..install(posthog);

    final manager = posthog.getProperty<JSObject>('scrollManager'.toJS);

    expect(manager.callMethod<JSNumber>('scrollX'.toJS).toDartDouble, 0);
  });

  test('after dispose a click no longer changes what the library reads',
      () async {
    final posthog = _fakePosthog();
    heatmap = _heatmap(_Scroll())..install(posthog);
    heatmap.dispose();
    double? seen;
    final listener = ((web.Event _) => seen = _scrollY(posthog)).toJS;
    web.document.addEventListener('click', listener);
    addTearDown(() => web.document.removeEventListener('click', listener));

    web.document.body!.dispatchEvent(
        web.MouseEvent('click', web.MouseEventInit(bubbles: true)));
    await Future<void>.delayed(Duration.zero);

    expect(seen, 480);
  });

  group('scrub, the last step before a heatmap event is sent', () {
    const origin = 'https://app.example.com';

    JSAny? scrub(Map<String, Object?> event) {
      heatmap = _heatmap(_Scroll());
      return heatmap.scrub(event.jsify());
    }

    Map<Object?, Object?> sentData(JSAny? result) {
      final properties =
          (result! as JSObject).getProperty<JSAny?>('properties'.toJS);
      return ((properties.dartify()! as Map)[r'$heatmap_data'] as Map)
          .cast<Object?, Object?>();
    }

    test('the address of a click is replaced by its route pattern', () {
      final result = scrub({
        'event': r'$$heatmap',
        'properties': {
          r'$heatmap_data': {
            '$origin/#/nasabah/8f14e45f': [
              {'x': 10, 'y': 20, 'type': 'click'},
            ],
          },
        },
      });

      expect(sentData(result).keys, ['$origin/#/nasabah/:id']);
      expect(
        (sentData(result)['$origin/#/nasabah/:id'] as List).single,
        {'x': 10, 'y': 20, 'type': 'click'},
      );
    });
  });
}
