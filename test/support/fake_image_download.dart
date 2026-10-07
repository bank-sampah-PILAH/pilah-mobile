import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart' show debugNetworkImageHttpClientProvider;
import 'package:flutter_test/flutter_test.dart';

const _onePixelPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

/// A network image download the test releases in two steps, so the "loading"
/// frames of `Image.network` can be observed (flutter_test otherwise answers
/// every HTTP request with a 400).
///
/// [install] must be paired with [uninstall] inside the test body: the
/// framework checks painting debug variables before tear-downs run.
class FakeImageDownload {
  FakeImageDownload._() : bytes = base64Decode(_onePixelPng);

  final Uint8List bytes;
  final _controller = StreamController<List<int>>();

  static FakeImageDownload install() {
    final download = FakeImageDownload._();
    debugNetworkImageHttpClientProvider = () => _FakeClient(download);
    return download;
  }

  static void uninstall() => debugNetworkImageHttpClientProvider = null;

  /// Delivers half the image: the download is now in progress.
  void sendFirstHalf() => _controller.add(bytes.sublist(0, bytes.length ~/ 2));

  /// Delivers the rest and completes the download.
  void finish() {
    _controller.add(bytes.sublist(bytes.length ~/ 2));
    _controller.close();
  }
}

class _FakeClient extends Fake implements HttpClient {
  _FakeClient(this.download);

  final FakeImageDownload download;

  @override
  set autoUncompress(bool value) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeRequest(download);
}

class _FakeRequest extends Fake implements HttpClientRequest {
  _FakeRequest(this.download);

  final FakeImageDownload download;

  @override
  Future<HttpClientResponse> close() async => _FakeResponse(download);
}

class _FakeResponse extends Fake implements HttpClientResponse {
  _FakeResponse(this.download);

  final FakeImageDownload download;

  @override
  int get statusCode => 200;

  @override
  int get contentLength => download.bytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      download._controller.stream.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);
}
