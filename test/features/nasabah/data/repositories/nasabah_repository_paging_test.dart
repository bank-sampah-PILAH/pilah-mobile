import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/nasabah/data/datasources/nasabah_remote_data_source.dart';
import 'package:pilah_mobile/features/nasabah/data/repositories/nasabah_repository_impl.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';

class _MockRemote extends Mock implements NasabahRemoteDataSource {}

NasabahEntity _nasabah(String nomor) => NasabahEntity(
      id: nomor,
      idNasabah: nomor,
      name: 'Nasabah $nomor',
      phone: '08123456789',
      balance: 'Rp 0',
      isActive: true,
      address: 'Jl. Melati',
      initials: 'NN',
      avatarColor: const Color(0xFFEAF5EC),
      textColor: const Color(0xFF2F6B45),
      jenisKelamin: 'Laki-laki',
      tanggalLahir: '01/01/1990',
      status: 'approved',
    );

void main() {
  late _MockRemote remote;
  late NasabahRepositoryImpl repository;

  final halaman = HalamanNasabah(
    items: [_nasabah('NAS-0001')],
    totalCount: 42,
    hasMore: true,
  );

  setUp(() {
    remote = _MockRemote();
    repository = NasabahRepositoryImpl(remote);
  });

  test('passes page, status and search straight through to the data source',
      () async {
    when(() => remote.getNasabah(
          page: any(named: 'page'),
          status: any(named: 'status'),
          search: any(named: 'search'),
        )).thenAnswer((_) async => halaman);

    final hasil = await repository.getNasabah(
      page: 3,
      status: 'menunggu',
      search: 'budi',
    );

    expect(hasil.toOption().toNullable()?.totalCount, 42);
    verify(() => remote.getNasabah(page: 3, status: 'menunggu', search: 'budi'))
        .called(1);
  });

  test('defaults to the first page of the aktif tab with no search', () async {
    when(() => remote.getNasabah(
          page: any(named: 'page'),
          status: any(named: 'status'),
          search: any(named: 'search'),
        )).thenAnswer((_) async => halaman);

    await repository.getNasabah();

    verify(() => remote.getNasabah(page: 1, status: 'aktif', search: null))
        .called(1);
  });

  test('picker fetch reaches the data source unpaged', () async {
    when(() => remote.getActiveNasabah()).thenAnswer((_) async => halaman);

    final hasil = await repository.getActiveNasabah();

    expect(hasil.isRight(), isTrue);
    verify(() => remote.getActiveNasabah()).called(1);
  });

  test('turns a data source failure into a Left', () async {
    when(() => remote.getNasabah(
          page: any(named: 'page'),
          status: any(named: 'status'),
          search: any(named: 'search'),
          // Data source selalu async, jadi kegagalannya datang sebagai Future
          // yang error, bukan lemparan sinkron.
        )).thenAnswer((_) async => throw Exception('jaringan putus'));

    final hasil = await repository.getNasabah();

    expect(hasil.isLeft(), isTrue);
  });
}
