import 'dart:convert';

import 'package:pilah_mobile/core/client/app_environment.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

import 'network_utils.dart';

@LazySingleton()
class NetworkService {
  final AppEnvironment environment;
  final NetworkUtils networkUtils;

  NetworkService({
    required this.environment,
    required this.networkUtils,
  });

  Map<String, String> headersRequest() {
    final userToken = networkUtils.accessToken;
    return {
      'Content-Type': 'application/json',
      if (userToken.isNotEmpty) 'Authorization': 'Bearer $userToken',
      'Accept': 'application/json'
    };
  }

  final dio = Dio()..interceptors.add(interceptors);

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

  /// POSTs multipart form data (e.g. file uploads). Unlike [post], this does
  /// NOT force `Content-Type: application/json` — Dio sets
  /// `multipart/form-data` with the correct boundary from [formData].
  Future<Response> postMultipart(
    String path, {
    required FormData formData,
  }) async {
    final userToken = networkUtils.accessToken;
    final headers = <String, String>{
      'Accept': 'application/json',
      if (userToken.isNotEmpty) 'Authorization': 'Bearer $userToken',
    };

    Response response = await dio
        .post(environment.baseUrl + path,
            data: formData,
            options: options.copyWith(headers: headers))
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
      'api': options.path,
      'headers': options.headers,
      'queryParams': options.queryParameters,
    });
  }
  return handler.next(options);
}, onResponse: (resp, handler) {
  if (kDebugMode) {
    final isBytes = resp.requestOptions.responseType == ResponseType.bytes;
    Logger().i({
      'api': '''
${resp.statusCode}: ${resp.requestOptions.baseUrl}${resp.requestOptions.path}''',
      'headers': resp.requestOptions.headers,
      'queryParams': resp.requestOptions.queryParameters,
      'body': resp.requestOptions.data,
      'response': isBytes ? 'bytes' : resp.data,
    });
  }
  return handler.next(resp);
}, onError: (err, handler) {
  if (kDebugMode) {
    Logger().e({
      'api': '''
${err.response?.statusCode ?? 0}: ${err.requestOptions.baseUrl}${err.requestOptions.path}''',
      'headers': err.requestOptions.headers,
      'queryParams': err.requestOptions.queryParameters,
      'body': err.requestOptions.data,
      'response': err.response?.data,
      'type': err.type
    });
  }
  return handler.next(err);
});

final options = Options(
  receiveTimeout: const Duration(milliseconds: 120000),
  sendTimeout: const Duration(milliseconds: 120000),
);

const Duration globalTimeout = Duration(seconds: 15);
