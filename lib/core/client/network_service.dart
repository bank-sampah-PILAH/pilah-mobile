import 'dart:convert';

import 'package:pilah_mobile/core/client/app_environment.dart';
import 'package:pilah_mobile/core/client/retry_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

import 'network_utils.dart';

@LazySingleton()
class NetworkService {
  static const _jsonContentType = 'application/json';
  final AppEnvironment environment;
  final NetworkUtils networkUtils;

  NetworkService({
    required this.environment,
    required this.networkUtils,
  }) {
    dio.interceptors.add(interceptors);
    // Added after the logger so a dropped GET is still logged, then quietly
    // retried once before the failure reaches state handling.
    dio.interceptors.add(RetryInterceptor(dio));
  }

  Map<String, String> headersRequest() {
    final userToken = networkUtils.accessToken;
    return {
      'Content-Type': _jsonContentType,
      if (userToken.isNotEmpty) 'Authorization': 'Bearer $userToken',
      'Accept': _jsonContentType
    };
  }

  final Dio dio = Dio();

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    /// If a key of [other] is already in this map, its value is overwritten.
    headers?.addAll(headersRequest());

    Response response = await dio
        .get(environment.baseUrl + path,
            queryParameters: queryParams,
            options: options.copyWith(
              headers: headers ?? headersRequest(),
            ))
        .timeout(globalTimeout);
    return response;
  }

  Future<Response> post(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    Map<String, dynamic>? data,
    FormData? formData,
  }) async {
    /// If a key of [other] is already in this map, its value is overwritten.
    headers?.addAll(headersRequest());

    Response response = await dio
        .post(environment.baseUrl + path,
            queryParameters: queryParams,
            data: formData ?? json.encode(data),
            options: options.copyWith(
              headers: headers ?? headersRequest(),
            ))
        .timeout(globalTimeout);
    return response;
  }

  /// GETs a binary payload (e.g. an XLSX export). Returns the raw [Response] so
  /// the caller can read both `response.data` (bytes) and headers such as
  /// `content-disposition`.
  Future<Response> getBytes(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    final userToken = networkUtils.accessToken;
    final headers = <String, String>{
      'Accept': '*/*',
      if (userToken.isNotEmpty) 'Authorization': 'Bearer $userToken',
    };

    Response response = await dio
        .get(environment.baseUrl + path,
            queryParameters: queryParams,
            options: options.copyWith(
              headers: headers,
              responseType: ResponseType.bytes,
            ))
        .timeout(globalTimeout);
    return response;
  }

  /// POSTs JSON and gets a binary payload back (e.g. an export of what is on
  /// screen). Like [getBytes], it returns the raw [Response] for its headers.
  Future<Response> postBytes(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? data,
  }) async {
    final headers = headersRequest()..['Accept'] = '*/*';
    Response response = await dio
        .post(environment.baseUrl + path,
            queryParameters: queryParams,
            data: json.encode(data),
            options: options.copyWith(
              headers: headers,
              responseType: ResponseType.bytes,
            ))
        .timeout(globalTimeout);
    return response;
  }

  /// POSTs multipart form data (e.g. file uploads). Unlike [post], this does
  /// NOT force `Content-Type: application/json` — Dio sets
  /// `multipart/form-data` with the correct boundary from [formData].
  Future<Response> postMultipart(
    String path, {
    required FormData formData,
  }) async {
    final userToken = networkUtils.accessToken;
    final headers = <String, String>{
      'Accept': _jsonContentType,
      if (userToken.isNotEmpty) 'Authorization': 'Bearer $userToken',
    };

    Response response = await dio
        .post(environment.baseUrl + path,
            data: formData, options: options.copyWith(headers: headers))
        .timeout(globalTimeout);
    return response;
  }

  /// PUTs multipart form data (e.g. a profile edit carrying a logo). The
  /// multipart counterpart to [put] for the same reason [postMultipart] is one
  /// to [post]: [headersRequest] pins `Content-Type: application/json`, which
  /// overrides the `multipart/form-data` Dio derives from [formData] and takes
  /// the boundary with it, leaving the server a body it cannot parse.
  Future<Response> putMultipart(
    String path, {
    required FormData formData,
  }) async {
    final userToken = networkUtils.accessToken;
    final headers = <String, String>{
      'Accept': _jsonContentType,
      if (userToken.isNotEmpty) 'Authorization': 'Bearer $userToken',
    };

    Response response = await dio
        .put(environment.baseUrl + path,
            data: formData, options: options.copyWith(headers: headers))
        .timeout(globalTimeout);
    return response;
  }

  Future<Response> put(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    Map<String, dynamic>? data,
    FormData? formData,
  }) async {
    final Map<String, String> defaultHeaders = headersRequest();

    /// If a key of [other] is already in this map, its value is overwritten.
    if (headers != null) {
      defaultHeaders.addAll(headers);
    }

    Response response = await dio
        .put(environment.baseUrl + path,
            queryParameters: queryParams,
            data: formData ?? json.encode(data),
            options: options.copyWith(
              headers: defaultHeaders,
            ))
        .timeout(globalTimeout);
    return response;
  }

  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    Map<String, dynamic>? data,
  }) async {
    /// If a key of [other] is already in this map, its value is overwritten.
    headers?.addAll(headersRequest());

    Response response = await dio
        .delete(environment.baseUrl + path,
            queryParameters: queryParams,
            data: json.encode(data),
            options: options.copyWith(
              headers: headers ?? headersRequest(),
            ))
        .timeout(globalTimeout);
    return response;
  }

  Future<Response> patch(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    Map<String, dynamic>? data,
  }) async {
    /// If a key of [other] is already in this map, its value is overwritten.
    headers?.addAll(headersRequest());

    Response response = await dio
        .patch(environment.baseUrl + path,
            queryParameters: queryParams,
            data: json.encode(data),
            options: options.copyWith(
              headers: headers ?? headersRequest(),
            ))
        .timeout(globalTimeout);
    return response;
  }
}

final interceptors = QueuedInterceptorsWrapper(onRequest: (options, handler) {
  if (kDebugMode) {
    Logger().i({
      'event': 'http_request',
      'method': _methodForLog(options.method),
      'request': '[REDACTED]',
    });
  }
  return handler.next(options);
}, onResponse: (resp, handler) {
  if (kDebugMode) {
    Logger().i({
      'event': 'http_response',
      'method': _methodForLog(resp.requestOptions.method),
      'status': resp.statusCode,
      'response': '[REDACTED]',
    });
  }
  return handler.next(resp);
}, onError: (err, handler) {
  if (kDebugMode) {
    Logger().e({
      'event': 'http_error',
      'method': _methodForLog(err.requestOptions.method),
      'status': err.response?.statusCode ?? 0,
      'type': err.type.name,
      'request': '[REDACTED]',
      'response': '[REDACTED]',
      // Keep the cause category for diagnosis, never its raw message: a
      // decoder or server error may contain tokens or customer records.
      'errorType': err.error?.runtimeType.toString(),
    });
  }
  return handler.next(err);
});

// URLs, headers, query values, bodies and response payloads are deliberately
// absent from debug logs. Even their paths or exception text can carry PII.
String _methodForLog(String method) => const {
      'GET',
      'POST',
      'PUT',
      'PATCH',
      'DELETE',
      'HEAD',
      'OPTIONS'
    }.contains(method)
        ? method
        : 'OTHER';

final options = Options(
  receiveTimeout: const Duration(milliseconds: 120000),
  sendTimeout: const Duration(milliseconds: 120000),
);

const Duration globalTimeout = Duration(seconds: 15);
