import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/riwayat_pencairan_filter.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_state.dart';

class _MockGetTransaksiUseCase extends Mock implements GetTransaksiUseCase {}

class _MockPencairanUseCases extends Mock implements PencairanUseCases {}

class _MockExportTransaksiUseCase extends Mock
    implements ExportTransaksiUseCase {}

TransaksiEntity _setoran(String name, DateTime tanggal) => TransaksiEntity(
      initials: 'NN',
      avatarColor: const Color(0xFFEAF5EC),
      textColor: const Color(0xFF2F6B45),
      name: name,
      subtitle: 'Plastik PET • 2 kg',
      amount: '+Rp 7.000',
      isWaSuccess: true,
      balance: 'Rp 0',
      items: const [],
      tanggal: tanggal,
    );

Pencairan _pencairan(String name, DateTime tanggal) => Pencairan(
      id: 'p-1',
      nasabahNama: name,
      nominal: 50000,
      metode: MetodePencairan.tunai,
      tanggal: tanggal,
      keterangan: '',
      status: 'tercatat',
      saldoSebelum: 100000,
      saldoSesudah: 50000,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(const TransaksiFilter());
    registerFallbackValue(const RiwayatPencairanFilter());
  });

  late _MockGetTransaksiUseCase getTransaksi;
  late _MockPencairanUseCases pencairanUseCases;
  late _MockExportTransaksiUseCase exportTransaksi;
  late RiwayatAktivitasCubit cubit;

  setUp(() {
    getTransaksi = _MockGetTransaksiUseCase();
    pencairanUseCases = _MockPencairanUseCases();
    exportTransaksi = _MockExportTransaksiUseCase();
    cubit = RiwayatAktivitasCubit(getTransaksi, pencairanUseCases, exportTransaksi);
  });

  tearDown(() => cubit.close());

  test('merges setoran and pencairan sorted by newest first',
      () async {
    when(() => getTransaksi.execute(any())).thenAnswer(
      (_) async => Right([
        TransaksiGroupEntity(
          header: 'HARI INI',
          transactions: [_setoran('Budi', DateTime(2026, 9, 22, 8))],
        ),
      ]),
    );
    when(() => pencairanUseCases.getRiwayat(any())).thenAnswer(
      (_) async => Right([_pencairan('Ani', DateTime(2026, 9, 22, 10))]),
    );

    await cubit.load();

    expect(cubit.state.items.map((e) => e.title), ['Ani', 'Budi']);
    expect(cubit.state.items[0].tipe, ActivitasTipe.pencairan);
    expect(cubit.state.items[1].tipe, ActivitasTipe.setoran);
  });

  test('degrades to setoran-only when the pencairan fetch fails',
      () async {
    when(() => getTransaksi.execute(any())).thenAnswer(
      (_) async => Right([
        TransaksiGroupEntity(
          header: 'HARI INI',
          transactions: [_setoran('Budi', DateTime(2026, 9, 22, 8))],
        ),
      ]),
    );
    when(() => pencairanUseCases.getRiwayat(any())).thenAnswer(
      (_) async => Left(NetworkException(message: 'Layanan sibuk')),
    );

    await cubit.load();

    expect(cubit.state.items, hasLength(1));
    expect(cubit.state.items.single.title, 'Budi');
  });

  test('surfaces a failure when the setoran fetch itself fails',
      () async {
    when(() => getTransaksi.execute(any())).thenAnswer(
      (_) async => Left(NetworkException(message: 'Gagal memuat')),
    );

    await cubit.load();

    expect(cubit.state.status, AktivitasStatus.failure);
    expect(cubit.state.errorMessage, 'Gagal memuat');
    verifyNever(() => pencairanUseCases.getRiwayat(any()));
  });

  test('skips the pencairan fetch for a custom setoran date range',
      () async {
    when(() => getTransaksi.execute(any())).thenAnswer((_) async => Right([]));

    cubit.applyCustomRange(DateTime(2026, 1, 1), DateTime(2026, 1, 31));
    await Future<void>.delayed(Duration.zero);

    verifyNever(() => pencairanUseCases.getRiwayat(any()));
  });

  test('filters by tipe without refetching', () async {
    when(() => getTransaksi.execute(any())).thenAnswer(
      (_) async => Right([
        TransaksiGroupEntity(
          header: 'HARI INI',
          transactions: [_setoran('Budi', DateTime(2026, 9, 22, 8))],
        ),
      ]),
    );
    when(() => pencairanUseCases.getRiwayat(any())).thenAnswer(
      (_) async => Right([_pencairan('Ani', DateTime(2026, 9, 22, 10))]),
    );
    await cubit.load();

    cubit.setTipeFilter(AktivitasTipeFilter.pencairan);

    expect(cubit.state.items, hasLength(1));
    expect(cubit.state.items.single.title, 'Ani');
    verify(() => getTransaksi.execute(any())).called(1);
  });

  test('searches by name across both types', () async {
    when(() => getTransaksi.execute(any())).thenAnswer(
      (_) async => Right([
        TransaksiGroupEntity(
          header: 'HARI INI',
          transactions: [_setoran('Budi Santoso', DateTime(2026, 9, 22, 8))],
        ),
      ]),
    );
    when(() => pencairanUseCases.getRiwayat(any())).thenAnswer(
      (_) async => Right([_pencairan('Ani Wijaya', DateTime(2026, 9, 22, 10))]),
    );
    await cubit.load();

    cubit.search('budi');

    expect(cubit.state.items, hasLength(1));
    expect(cubit.state.items.single.title, 'Budi Santoso');
  });
}
