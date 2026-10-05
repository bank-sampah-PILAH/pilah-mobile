import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/painting.dart' show debugNetworkImageHttpClientProvider;
import 'package:pilah_mobile/core/bases/widgets/proof_image_dialog.dart';

/// Pumps a host with a button that opens the dialog for [imageUrl].
///
/// Tears the tree down first so repeated calls within one test start from a
/// fresh Navigator, rather than tapping at a button sitting behind the previous
/// dialog's barrier.
Future<void> _openDialog(WidgetTester tester, {String? imageUrl}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showProofImageDialog(context, imageUrl: imageUrl),
          child: const Text('Lihat Bukti'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('Lihat Bukti'));
  await tester.pump();
}

/// The URL every rendered [Image.network] in the tree is pointing at.
List<String> _renderedNetworkUrls(WidgetTester tester) => tester
    .widgetList<Image>(find.byType(Image))
    .map((i) => i.image)
    .whereType<NetworkImage>()
    .map((n) => n.url)
    .toList();

void main() {
  group('showProofImageDialog', () {
    testWidgets('with no photo on record, shows nothing rather than a stand-in',
        (tester) async {
      await _openDialog(tester, imageUrl: null);

      expect(find.text('Tidak ada foto kegiatan'), findsOneWidget);
      expect(
        _renderedNetworkUrls(tester),
        isEmpty,
        reason: 'a superadmin must never approve against a stand-in image',
      );
    });

    testWidgets('an empty url counts as no photo, not a broken one',
        (tester) async {
      await _openDialog(tester, imageUrl: '   ');

      expect(find.text('Tidak ada foto kegiatan'), findsOneWidget);
      expect(_renderedNetworkUrls(tester), isEmpty);
    });

    testWidgets('with a real url, loads exactly that url', (tester) async {
      const url = 'https://storage.googleapis.com/pilah/kegiatan/bukti.jpg';
      await _openDialog(tester, imageUrl: url);

      expect(_renderedNetworkUrls(tester), [url]);
      expect(find.text('Tidak ada foto kegiatan'), findsNothing);
    });

    testWidgets('never falls back to a stock photo service', (tester) async {
      for (final input in <String?>[null, '', '  ']) {
        await _openDialog(tester, imageUrl: input);
        final urls = _renderedNetworkUrls(tester).join(' ');
        expect(
          urls.contains('picsum') || urls.contains('placeholder'),
          isFalse,
          reason: 'the picsum dummy must not come back for input: $input',
        );
      }
    });
  });

  group('closing', () {
    testWidgets('the close icon dismisses the dialog', (tester) async {
      await _openDialog(tester, imageUrl: null);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Tidak ada foto kegiatan'), findsNothing);
    });

    testWidgets('the Close button dismisses the dialog', (tester) async {
      // Tall enough that the button is inside the screen, so the tap cannot
      // land on the dismissible barrier instead.
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _openDialog(tester, imageUrl: null);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Tidak ada foto kegiatan'), findsNothing);
    });
  });

  group('photo that has to be fetched', () {
    testWidgets(
        'a photo that cannot be fetched is reported as a network '
        'problem, not as a missing photo', (tester) async {
      // flutter_test answers every real HTTP request with a 400.
      await _openDialog(tester, imageUrl: 'https://example.test/bukti.jpg');
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();

      expect(find.text('Gagal memuat gambar'), findsOneWidget);
      expect(find.text('Tidak ada foto kegiatan'), findsNothing);
      tester.takeException();
    });

    testWidgets('shows progress while the photo downloads, then the photo',
        (tester) async {
      final body = _FakeBody(base64Decode(_onePixelPng));
      debugNetworkImageHttpClientProvider = () => _FakeClient(body);
      // Reset inside the body: the framework checks painting debug variables
      // before group tear-downs run.

      await _openDialog(tester, imageUrl: 'https://example.test/bukti.jpg');
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      body.sendFirstHalf();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      body.finish();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Gagal memuat gambar'), findsNothing);
      debugNetworkImageHttpClientProvider = null;
    });
  });
}

const _onePixelPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

/// A response body the test releases in two steps.
class _FakeBody {
  _FakeBody(this.bytes);

  final Uint8List bytes;
  final controller = StreamController<List<int>>();

  void sendFirstHalf() => controller.add(bytes.sublist(0, bytes.length ~/ 2));

  void finish() {
    controller.add(bytes.sublist(bytes.length ~/ 2));
    controller.close();
  }
}

class _FakeClient extends Fake implements HttpClient {
  _FakeClient(this.body);

  final _FakeBody body;

  @override
  set autoUncompress(bool value) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeRequest(body);
}

class _FakeRequest extends Fake implements HttpClientRequest {
  _FakeRequest(this.body);

  final _FakeBody body;

  @override
  Future<HttpClientResponse> close() async => _FakeResponse(body);
}

class _FakeResponse extends Fake implements HttpClientResponse {
  _FakeResponse(this.body);

  final _FakeBody body;

  @override
  int get statusCode => 200;

  @override
  int get contentLength => body.bytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      body.controller.stream.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);
}
