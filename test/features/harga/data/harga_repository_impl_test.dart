import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/core/utils/formatter/date_time_formatter.dart';
import 'package:pilah_mobile/features/harga/data/datasources/harga_remote_data_source_impl.dart';
import 'package:pilah_mobile/features/harga/data/repositories/harga_repository_impl.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/domain/entities/ubah_harga.dart';
import 'package:pilah_mobile/features/harga/domain/entities/versi_harga.dart';

class _MockNetworkService extends Mock implements NetworkService {}

Response<dynamic> _ok(String path) => Response<dynamic>(
      requestOptions: RequestOptions(path: path),
      data: <String, dynamic>{},
      statusCode: 201,
    );

void main() {
  late _MockNetworkService network;
  late HargaRepositoryImpl repository;

  setUp(() {
    network = _MockNetworkService();
    repository = HargaRepositoryImpl(HargaRemoteDataSourceImpl(network));
  });

  group('ubahHarga', () {
    const path = '/api/v1/jenis-sampah/j-1/harga';

    setUp(() {
      when(() => network.post(path, data: any(named: 'data')))
          .thenAnswer((_) async => _ok(path));
    });

    test('posts a scheduled price with its local start time and offset',
        () async {
      final tengahMalam = DateTime(2026, 10, 15);

      final result = await repository.ubahHarga(
        UbahHarga(id: 'j-1', harga: 5000, berlakuMulai: tengahMalam),
      );

      expect(result, const Right<NetworkException, void>(null));
      final data = verify(
        () => network.post(path, data: captureAny(named: 'data')),
      ).captured.single;
      expect(data, {
        'harga_per_kg': '5000',
        'berlaku_mulai': isoDenganOffset(tengahMalam),
      });
    });

    test('turns a failed request into a NetworkException', () async {
      when(() => network.post(path, data: any(named: 'data')))
          .thenThrow(Exception('offline'));

      final result =
          await repository.ubahHarga(const UbahHarga(id: 'j-1', harga: 4000));

      expect(result.isLeft(), isTrue);
    });

    test('leaves berlaku_mulai out so the price applies now', () async {
      await repository.ubahHarga(const UbahHarga(id: 'j-1', harga: 4000));

      final data = verify(
        () => network.post(path, data: captureAny(named: 'data')),
      ).captured.single;
      expect(data, {'harga_per_kg': '4000'});
    });
  });

  group('getRiwayatHarga', () {
    const path = '/api/v1/jenis-sampah/j-1/harga';

    test('reads every version with its unit, start, author and status',
        () async {
      when(() => network.get(path, queryParams: any(named: 'queryParams')))
          .thenAnswer((_) async => Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 200,
                data: <String, dynamic>{
                  'count': 2,
                  'results': [
                    {
                      'id': 2,
                      'harga_per_kg': '5000.00',
                      'satuan': 'kg',
                      'berlaku_mulai': '2026-10-14T17:00:00Z',
                      'dibuat_oleh': 'Ibu Sari',
                      'status': 'terjadwal',
                    },
                    {
                      'id': 1,
                      'harga_per_kg': '3500.00',
                      'satuan': 'kg',
                      'berlaku_mulai': '2026-09-01T03:00:00Z',
                      'dibuat_oleh': null,
                      'status': 'berlaku',
                    },
                  ],
                },
              ));

      final result = await repository.getRiwayatHarga('j-1');

      expect(
        result.getOrElse(() => const []),
        [
          VersiHarga(
            harga: 5000,
            satuan: 'kg',
            berlakuMulai: DateTime.utc(2026, 10, 14, 17),
            dibuatOleh: 'Ibu Sari',
            status: StatusVersiHarga.terjadwal,
          ),
          VersiHarga(
            harga: 3500,
            satuan: 'kg',
            berlakuMulai: DateTime.utc(2026, 9, 1, 3),
            status: StatusVersiHarga.berlaku,
          ),
        ],
      );
      final query = verify(
        () => network.get(path, queryParams: captureAny(named: 'queryParams')),
      ).captured.single;
      expect(query, {'page_size': 100});
    });

    test('turns a failed request into a NetworkException', () async {
      when(() => network.get(path, queryParams: any(named: 'queryParams')))
          .thenThrow(Exception('offline'));

      final result = await repository.getRiwayatHarga('j-1');

      expect(result.isLeft(), isTrue);
    });
  });

  test('updateHarga no longer sends the price with the other fields', () async {
    const path = '/api/v1/jenis-sampah/j-1';
    when(() => network.put(path, data: any(named: 'data')))
        .thenAnswer((_) async => _ok(path));

    await repository.updateHarga(HargaEntity(
      id: 'j-1',
      kodeSampah: 'PLS-001',
      name: 'Plastik PET',
      price: 3500,
      priceFormatted: 'Rp 3.500',
      category: 'plastik',
      subtitle: '',
      badgeText: 'Anorganik',
      icon: Icons.recycling,
      iconColor: Colors.green,
      isActive: true,
    ));

    final data = verify(
      () => network.put(path, data: captureAny(named: 'data')),
    ).captured.single as Map<String, dynamic>;
    expect(data.containsKey('harga_per_kg'), isFalse);
    expect(data['nama_sampah'], 'Plastik PET');
  });
}
