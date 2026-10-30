import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/nasabah/data/datasources/nasabah_remote_data_source.dart';
import 'package:pilah_mobile/features/nasabah/data/repositories/nasabah_repository_impl.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';
import 'package:pilah_mobile/features/nasabah/presentation/states/nasabah_state.dart';

import '../../../../support/nasabah_support.dart';
import '../../../../support/notifier_harness.dart';
import '../../../../support/stub_api.dart';

class _Remote extends Mock implements NasabahRemoteDataSource {}

const _generic = 'Daftar nasabah gagal dimuat. Silakan coba lagi.';
const _timeout = 'Permintaan daftar nasabah terlalu lama. Silakan coba lagi.';
const _network = 'Tidak dapat terhubung. Periksa koneksi lalu coba lagi.';
const _rate = 'Terlalu banyak permintaan. Tunggu sebentar lalu coba lagi.';

DioException _http(int status) {
  final options = RequestOptions(path: '/api/v1/nasabah');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: options,
      statusCode: status,
      data: {'error': 'private-stack-and-customer@example.test'},
    ),
  );
}

void main() {
  final failures = <(String, Object, String)>[
    ('unexpected error', Exception('private-exception'), _generic),
    ('malformed data', const FormatException('private-source'), _generic),
    ('type mismatch', StateError('private-response'), _generic),
    ('outer timeout', TimeoutException('private-timeout'), _timeout),
    ('server error', _http(500), _generic),
    ('HTML error', _http(502), _generic),
    ('service unavailable', _http(503), _generic),
    ('rate limit', _http(429), _rate),
    (
      'expired session',
      _http(401),
      'Sesi Anda telah berakhir. Silakan masuk kembali.'
    ),
    (
      'forbidden',
      _http(403),
      'Anda tidak memiliki akses ke daftar nasabah ini.'
    ),
    ('invalid query', _http(422), 'Pencarian atau filter nasabah tidak valid.'),
    (
      'connection timeout',
      DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionTimeout),
      _timeout
    ),
    (
      'receive timeout',
      DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.receiveTimeout),
      _timeout
    ),
    (
      'network failure',
      DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError),
      _network
    ),
  ];

  for (final (name, error, message) in failures) {
    test('customer-list $name returns a fixed safe message', () async {
      final remote = _Remote();
      when(() => remote.getNasabah(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            status: any(named: 'status'),
            search: any(named: 'search'),
            urutan: any(named: 'urutan'),
          )).thenAnswer((_) async => throw error);
      final result = await NasabahRepositoryImpl(remote).getNasabah();
      final display =
          result.fold((failure) => failure.displayMessage, (_) => 'success');
      expect(display, message);
      expect(display, isNot(contains('private-')));
    });
  }

  test('rate-limited list retries without losing status or search', () async {
    final api = StubApi();
    api.on('GET', '/api/v1/nasabah', json: nasabahPage([]));
    final harness =
        NotifierHarness(nasabahProvider, () => buildNasabahNotifier(api));
    addTearDown(harness.dispose);
    final notifier = harness.notifier;
    await notifier.loadNasabah();
    await notifier.setActiveTab(null);
    notifier.searchNasabah('budi');
    api.on('GET', '/api/v1/nasabah',
        status: 429, json: {'error': 'private-trace'});
    await notifier.loadNasabah();
    expect((notifier.state as NasabahError).message, _rate);
    api.on('GET', '/api/v1/nasabah', json: nasabahPage([nasabahRow('1')]));
    await notifier.loadNasabah();
    expect(notifier.state, isA<NasabahLoaded>());
    expect(api.last.query['status'], 'menunggu');
    expect(api.last.query['search'], 'budi');
  });
}
