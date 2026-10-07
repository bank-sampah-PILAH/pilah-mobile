import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_aktivitas_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_state.dart';

class Feed extends Mock implements GetAktivitasUseCase {}

class Export extends Mock implements ExportTransaksiUseCase {}

ActivitasEntity item(String id) =>
    ActivitasEntity.fromTransaksi(TransaksiEntity(
      id: id,
      initials: 'SI',
      avatarColor: Colors.green,
      textColor: Colors.black,
      name: 'Siti',
      subtitle: 'Plastik',
      amount: '+Rp 10.000',
      isWaSuccess: false,
      balance: '',
      items: const [],
      tanggal: DateTime(2026, 10, 7),
    ));

void main() {
  setUpAll(() => registerFallbackValue(const TransaksiFilter()));
  late Feed feed;
  late RiwayatAktivitasCubit cubit;
  setUp(() {
    feed = Feed();
    cubit = RiwayatAktivitasCubit(feed, Export());
    when(() => feed.execute(any()))
        .thenAnswer((_) async => const Right(AktivitasPage([], false)));
  });
  tearDown(() => cubit.close());

  test('appends pages and deduplicates overlapping rows', () async {
    when(() => feed.execute(any())).thenAnswer((invocation) async {
      final filter = invocation.positionalArguments.first as TransaksiFilter;
      return Right(filter.page == 1
          ? AktivitasPage([item('a')], true)
          : AktivitasPage([item('a'), item('b')], false));
    });
    await cubit.load();
    await cubit.loadMore();
    expect(cubit.state.items.map((e) => e.transaksi!.id), ['a', 'b']);
    expect(cubit.state.hasNext, false);
    await cubit.loadMore();
    verify(() => feed.execute(any())).called(2);
  });

  test('custom dates and type are sent to the same endpoint', () async {
    cubit.applyCustomRange(DateTime(2026, 9, 1), DateTime(2026, 9, 30));
    await Future<void>.delayed(Duration.zero);
    cubit.setTipeFilter(AktivitasTipeFilter.pencairan);
    await Future<void>.delayed(Duration.zero);
    final filters = verify(() => feed.execute(captureAny()))
        .captured
        .cast<TransaksiFilter>();
    expect(filters.last.toQueryParams(), containsPair('tipe', 'pencairan'));
    expect(filters.last.toQueryParams(),
        containsPair('dari_tanggal', '2026-09-01'));
    expect(filters.last.page, 1);
    cubit.setPeriode('minggu_ini');
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.dariTanggal, isNull);
  });

  test('search is applied server-side and resets pagination', () async {
    cubit.search('Siti');
    await Future<void>.delayed(Duration.zero);
    final filter = verify(() => feed.execute(captureAny())).captured.single
        as TransaksiFilter;
    expect(filter.toQueryParams(), containsPair('search', 'Siti'));
    expect(filter.page, 1);
  });

  test('failed next page retains items and retries the same page', () async {
    var nextCalls = 0;
    when(() => feed.execute(any())).thenAnswer((invocation) async {
      final filter = invocation.positionalArguments.first as TransaksiFilter;
      if (filter.page == 1) return Right(AktivitasPage([item('a')], true));
      if (++nextCalls == 1) return Left(NetworkException(message: 'Offline'));
      return Right(AktivitasPage([item('b')], false));
    });
    await cubit.load();
    await cubit.loadMore();
    expect(cubit.state.items, hasLength(1));
    expect(cubit.state.errorMessage, isNotNull);
    await cubit.loadMore();
    expect(cubit.state.items, hasLength(2));
  });

  test('late responses cannot replace a newer filter or repopulate logout',
      () async {
    final pending = Completer<Either<NetworkException, AktivitasPage>>();
    when(() => feed.execute(any())).thenAnswer((_) => pending.future);
    final loading = cubit.load();
    cubit.reset();
    pending.complete(Right(AktivitasPage([item('old')], false)));
    await loading;
    expect(cubit.state.status, AktivitasStatus.initial);
    expect(cubit.state.items, isEmpty);
  });
}
