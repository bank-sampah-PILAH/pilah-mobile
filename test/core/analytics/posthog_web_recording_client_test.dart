@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/analytics/posthog_web_recording_client.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:posthog_flutter/src/posthog_flutter_platform_interface.dart';
import 'package:web/web.dart' as web;

/// The plugin's side of the web, recording what the app asks of it and when
/// the browser library had been initialised by then.
class _FakePlatform extends PosthogFlutterPlatformInterface
    with MockPlatformInterfaceMixin {
  PostHogConfig? config;
  List<String>? libraryCallsAtSetup;
  Completer<void>? setupGate;

  @override
  Future<void> setup(PostHogConfig config) async {
    this.config = config;
    final calls = globalContext.getProperty<JSAny?>('__calls'.toJS).dartify();
    libraryCallsAtSetup = (calls as List<Object?>?)?.cast<String>().toList();
    await setupGate?.future;
  }
}

final _fakeLibraryUrl = Uri.base.resolve('fake_posthog_library.js').toString();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakePlatform platform;
  late PosthogWebRecordingClient client;
  final original = PosthogFlutterPlatformInterface.instance;

  setUp(() {
    platform = _FakePlatform();
    PosthogFlutterPlatformInterface.instance = platform;
    client = PosthogWebRecordingClient(
      apiKey: 'phc_test',
      host: 'https://us.i.posthog.com',
      libraryUrl: _fakeLibraryUrl,
    );
  });

  tearDown(() {
    PosthogFlutterPlatformInterface.instance = original;
    final all = web.document.scripts;
    for (var i = all.length - 1; i >= 0; i--) {
      final script = all.item(i)! as web.HTMLScriptElement;
      if (script.src == _fakeLibraryUrl) script.remove();
    }
    globalContext
      ..delete('posthog'.toJS)
      ..delete('__calls'.toJS)
      ..delete('__captures'.toJS)
      ..delete('__identified'.toJS)
      ..delete('__registered'.toJS)
      ..delete('__initCalls'.toJS)
      ..delete('__initArgs'.toJS)
      ..delete('__optInOptions'.toJS);
  });

  test('records the screen, and the recorder waits for the library', () async {
    const app = SizedBox();

    expect(client.recordsScreen, isTrue);
    expect(client.wrapApp(app), same(app));

    await client.start();

    final wrapped = client.wrapApp(app);
    expect(wrapped, isA<PostHogWidget>());
    expect((wrapped as PostHogWidget).child, same(app));
  });

  test('hands the plugin the library only after it is set up, masked', () async {
    await client.start();

    // The plugin hooks into the library that is already running: if it ran
    // first it would find nothing to register its masks with.
    expect(platform.libraryCallsAtSetup, contains('init'));
    final config = platform.config!;
    expect(config.sessionReplay, isTrue);
    expect(config.sessionReplayConfig.maskAllTexts, isTrue);
    expect(config.sessionReplayConfig.maskAllImages, isTrue);
  });

  test('is not a recorder around the app when the library cannot load',
      () async {
    final broken = PosthogWebRecordingClient(
      apiKey: 'phc_test',
      host: 'https://us.i.posthog.com',
      libraryUrl: Uri.base.resolve('missing_library.js').toString(),
      loadTimeout: const Duration(seconds: 2),
    );
    const app = SizedBox();

    await expectLater(broken.start(), throwsStateError);

    expect(broken.wrapApp(app), same(app));
    expect(platform.config, isNull);
  });
}
