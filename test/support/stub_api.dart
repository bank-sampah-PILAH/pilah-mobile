import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/app_environment.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/core/client/network_utils.dart';
import 'package:pilah_mobile/core/database/secure_database.dart';

class _MockSecureDatabase extends Mock implements SecureDatabase {}

/// Fixed, fake environment so tests never read a real `.env`.
class StubEnvironment implements AppEnvironment {
  @override
  String get baseUrl => 'http://api.test';

  @override
  bool get supportsDemoLogin => true;

  @override
  String get demoPengurusEmail => 'pengurus@demo.test';

  @override
  String get demoPengelolaIndukEmail => 'induk@demo.test';

  @override
  String get demoCustomerEmail => 'customer@demo.test';

  @override
  String get demoNewNasabahEmail => 'baru@demo.test';

  @override
  String get demoSuperadminEmail => 'super@demo.test';
}

/// One request that reached the HTTP boundary.
class RecordedRequest {
  RecordedRequest(this.method, this.path, this.query, this.body, this.headers);

  final String method;
  final String path;
  final Map<String, dynamic> query;
  final Object? body;
  final Map<String, dynamic> headers;

  /// The JSON body, decoded.
  dynamic get json => body is String ? jsonDecode(body as String) : body;
}

/// A fake backend wired in at the HTTP boundary (Dio's adapter), so the real
/// [NetworkService], data sources, repositories, use cases and cubits run.
class StubApi implements HttpClientAdapter {
  StubApi({String accessToken = 'token-123'}) {
    final db = _MockSecureDatabase();
    utils = NetworkUtils(db);
    if (accessToken.isNotEmpty) {
      utils.setToken(accessToken: accessToken, refreshToken: 'refresh');
    }
    network =
        NetworkService(environment: StubEnvironment(), networkUtils: utils);
    network.dio.httpClientAdapter = this;
  }

  late final NetworkUtils utils;
  late final NetworkService network;
  final requests = <RecordedRequest>[];
  final _routes = <String, ResponseBody Function(RequestOptions)>{};

  /// When set, every answer takes this long to arrive, so a test can observe
  /// the loading frames a real network would produce.
  Duration? latency;

  RecordedRequest get last => requests.last;

  /// Answers `METHOD path` with a JSON body.
  void on(String method, String path, {int status = 200, Object? json}) {
    _routes['${method.toUpperCase()} $path'] = (_) => ResponseBody.fromString(
          jsonEncode(json),
          status,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
  }

  /// Answers `METHOD path` with raw bytes.
  void onBytes(String method, String path, List<int> bytes,
      {Map<String, List<String>> headers = const {}}) {
    _routes['${method.toUpperCase()} $path'] = (_) => ResponseBody.fromBytes(
          bytes,
          200,
          headers: headers,
        );
  }

  /// Re-answers an existing byte route with another status.
  void status(String method, String path, int code) {
    final inner = _routes['${method.toUpperCase()} $path']!;
    _routes['${method.toUpperCase()} $path'] = (options) {
      final body = inner(options);
      return ResponseBody(body.stream, code, headers: body.headers);
    };
  }

  /// Makes `METHOD path` fail at the transport level.
  void fail(String method, String path,
      [DioExceptionType type = DioExceptionType.connectionTimeout]) {
    _routes['${method.toUpperCase()} $path'] =
        (options) => throw DioException(requestOptions: options, type: type);
  }

  /// Makes `METHOD path` fail with a non-Dio error.
  void crash(String method, String path, Object error) {
    _routes['${method.toUpperCase()} $path'] = (_) => throw error;
  }

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    // Consume multipart streams like a real adapter, releasing file handles.
    await requestStream?.drain<void>();
    requests.add(RecordedRequest(
      options.method,
      options.uri.path,
      options.uri.queryParameters,
      options.data,
      Map<String, dynamic>.from(options.headers),
    ));
    if (latency != null) await Future<void>.delayed(latency!);
    final route = _routes['${options.method} ${options.uri.path}'];
    if (route == null) {
      return ResponseBody.fromString(
        jsonEncode(
            {'error': 'no stub for ${options.method} ${options.uri.path}'}),
        404,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return route(options);
  }

  @override
  void close({bool force = false}) {}
}
