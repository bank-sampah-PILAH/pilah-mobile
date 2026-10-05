import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/transaksi/data/datasources/transaksi_remote_data_source.dart';
import 'package:pilah_mobile/features/transaksi/data/datasources/transaksi_remote_data_source_impl.dart';
import 'package:pilah_mobile/features/transaksi/data/repositories/transaksi_repository_impl.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';

class _MockNetworkService extends Mock implements NetworkService {}

class _MockSource extends Mock implements TransaksiRemoteDataSource {}

class _FakeFilter extends Fake implements TransaksiFilter {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeFilter()));

  test('export accepts a byte payload delivered as a plain int list', () async {
    final network = _MockNetworkService();
    when(() => network.getBytes('/api/v1/transaksi/export',
            queryParams: any(named: 'queryParams')))
        .thenAnswer((_) async => Response<List<int>>(
              requestOptions: RequestOptions(path: '/export'),
              data: [4, 5, 6],
            ));

    final export = await TransaksiRemoteDataSourceImpl(network)
        .exportTransaksi(const TransaksiFilter());

    expect(export.bytes, Uint8List.fromList([4, 5, 6]));
  });

  test('the repository maps a non-Dio exception from the export source',
      () async {
    final source = _MockSource();
    when(() => source.exportTransaksi(any()))
        .thenThrow(const FormatException('x'));

    final result = await TransaksiRepositoryImpl(source)
        .exportTransaksi(const TransaksiFilter());

    expect(result.fold((l) => l, (r) => null), isA<GeneralException>());
  });

  test('copyWith keeps the WA status unless told otherwise', () {
    final entity = TransaksiEntity(
      initials: 'AB',
      avatarColor: Colors.red,
      textColor: Colors.white,
      name: 'Ab',
      subtitle: '',
      amount: '',
      isWaSuccess: true,
      balance: '',
      items: const [],
    );

    expect(entity.copyWith().isWaSuccess, isTrue);
    expect(entity.copyWith(isWaSuccess: false).isWaSuccess, isFalse);
  });

  test('the "semua" filter sends only the period', () {
    final filter = TransaksiFilter.semua(pageSize: int.parse('5'));

    expect(filter.toQueryParams(), {'periode': 'semua'});
    expect(filter.pageSize, 5);
  });
}
