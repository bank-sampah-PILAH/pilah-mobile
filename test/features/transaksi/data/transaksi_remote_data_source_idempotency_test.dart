import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/transaksi/data/datasources/transaksi_remote_data_source_impl.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';

class _MockNetworkService extends Mock implements NetworkService {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(<String, String>{});
  });

  test('reuses the request idempotency key in the request header', () async {
    const key = '00000000-0000-4000-8000-000000000001';
    final network = _MockNetworkService();
    final headers = <Map<String, String>>[];
    when(
      () => network.post(
        '/api/v1/transaksi',
        data: any(named: 'data'),
        headers: any(named: 'headers'),
      ),
    ).thenAnswer((invocation) async {
      headers.add(
        Map<String, String>.from(
          invocation.namedArguments[#headers] as Map<String, String>,
        ),
      );
      return Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/api/v1/transaksi'),
        data: {
          'id': 'transaksi-1',
          'total_nilai': '3333.00',
          'saldo_setelah_transaksi': '3333.00',
          'items': [],
        },
      );
    });

    final source = TransaksiRemoteDataSourceImpl(network);
    final request = TransaksiRequest(
      nasabahId: 'nasabah-1',
      items: [],
      idempotencyKey: key,
    );
    await source.addTransaksi(request);
    await source.addTransaksi(request);

    expect(headers, [
      {'Idempotency-Key': key},
      {'Idempotency-Key': key},
    ]);
  });
}
