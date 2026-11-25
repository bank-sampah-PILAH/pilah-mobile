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
}
