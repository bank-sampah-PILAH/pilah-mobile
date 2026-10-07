import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/riwayat/data/datasources/riwayat_remote_data_source.dart';
import 'package:pilah_mobile/features/riwayat/data/repositories/riwayat_repository_impl.dart';
import 'package:pilah_mobile/features/riwayat/domain/use_cases/riwayat_use_cases.dart';
import 'package:pilah_mobile/features/riwayat/presentation/cubit/riwayat_history_cubit.dart';
import 'package:pilah_mobile/features/statement/data/remote/statement_remote_data_sources.dart';
import 'package:pilah_mobile/features/statement/data/statement_repository_impl.dart';
import 'package:pilah_mobile/features/statement/domain/model/statement_export.dart';
import 'package:pilah_mobile/features/statement/domain/statement_interactor.dart';
import 'package:pilah_mobile/features/statement/domain/use_cases/statement_use_cases.dart';
import 'package:pilah_mobile/features/statement/presentation/blocs/statement_export_cubit.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/preview/preview_riwayat_repository.dart';

import '../../support/stub_api.dart';

class _UseCases extends Mock implements StatementUseCases {}

class _Nasabah extends Mock implements NasabahRepository {}

void main() {
  const path = '/api/v1/nasabah/me/riwayat';
  final detail = <String, dynamic>{
    'tanggal': '2026-10-01T08:00:00+07:00',
    'tipe': 'setoran',
    'total_nilai': '25000.00',
    'saldo_setelah_transaksi': '50000.00',
    'catatan': 'uji',
    'items': [],
  };

  test(
      'real history/detail/PDF pipeline preserves membership, page and payload',
      () async {
    final api = StubApi();
    api.on('GET', path, json: {
      'results': [
        {'id': 'tx-1', ...detail}
      ],
      'next': 'page=3',
    });
    api.on('GET', '$path/tx-1', json: detail);
    api.onBytes('GET', '$path/export-pdf', [
      37,
      80,
      68,
      70
    ], headers: {
      'content-disposition': ['attachment; filename="statement.pdf"'],
    });
    final repo =
        RiwayatRepositoryImpl(RiwayatRemoteDataSourceImpl(api.network));
    final history = (await GetRiwayatHistoryUseCase(repo)
            .execute(const RiwayatHistoryParams('member-1', page: 2)))
        .getOrElse(() => throw StateError('history failed'));
    expect(history.activities.single.id, 'tx-1');
    expect(history.hasNext, isTrue);
    expect(api.last.query, {'keanggotaan_id': 'member-1', 'page': '2'});
    final loaded = (await GetRiwayatSetoranDetailUseCase(repo).execute(
            const RiwayatSetoranDetailParams(
                membershipId: 'member-1', transactionId: 'tx-1')))
        .getOrElse(() => throw StateError('detail failed'));
    expect(loaded.amount, '25000.00');
    expect(api.last.query, {'keanggotaan_id': 'member-1'});
    final pdf = (await ExportRiwayatPdfUseCase(repo).execute('member-1'))
        .getOrElse(() => throw StateError('PDF failed'));
    expect(pdf.bytes, [37, 80, 68, 70]);
    expect(pdf.filename, 'statement.pdf');
    expect(api.last.query, {'keanggotaan_id': 'member-1'});
  });

  test('default use-case parameters and network failures remain typed',
      () async {
    final api = StubApi();
    api.on('GET', path, json: {'results': [], 'next': null});
    api.on('GET', '$path/', json: detail);
    api.onBytes('GET', '$path/export-pdf', [1]);
    final repo =
        RiwayatRepositoryImpl(RiwayatRemoteDataSourceImpl(api.network));
    expect((await GetRiwayatHistoryUseCase(repo).execute()).isRight(), isTrue);
    expect(api.last.query['page'], '1');
    expect(api.last.query['keanggotaan_id'], '');
    expect((await GetRiwayatSetoranDetailUseCase(repo).execute()).isRight(),
        isTrue);
    final pdf = (await ExportRiwayatPdfUseCase(repo).execute())
        .getOrElse(() => throw StateError('PDF failed'));
    expect(pdf.filename, 'Riwayat_Aktivitas.pdf');
    api.fail('GET', path);
    api.fail('GET', '$path/tx-1');
    api.fail('GET', '$path/export-pdf');
    expect((await repo.history('member-1')).isLeft(), isTrue);
    expect((await repo.setoranDetail('member-1', 'tx-1')).isLeft(), isTrue);
    expect((await repo.exportPdf('member-1')).isLeft(), isTrue);
  });

  test('statement pipeline emits loading, loaded and failure for the real API',
      () async {
    final api = StubApi();
    api.onBytes('GET', '$path/export-pdf', [
      1,
      2
    ], headers: {
      'content-disposition': ['attachment; filename=unquoted.pdf'],
    });
    final remote = StatementRemoteDataSourceImpl(api.network);
    final cubit = StatementExportCubit(
        StatementInteractor(StatementRepositoryImpl(remote)));
    addTearDown(cubit.close);
    final states = <StatementExportStatus>[];
    final subscription =
        cubit.stream.listen((state) => states.add(state.status));
    addTearDown(subscription.cancel);
    final pdf = await cubit.export('member-1');
    expect(pdf!.filename, 'unquoted.pdf');
    expect(pdf.bytes, [1, 2]);
    expect(
        cubit.state,
        StatementExportState(
            status: StatementExportStatus.loaded, export: pdf));
    expect(cubit.state.props, [StatementExportStatus.loaded, pdf, null]);
    api.fail('GET', '$path/export-pdf');
    expect(await cubit.export('member-1'), isNull);
    expect(cubit.state.status, StatementExportStatus.failure);
    expect(cubit.state.error, isNotEmpty);
    await Future<void>.delayed(Duration.zero);
    expect(states, [
      StatementExportStatus.loading,
      StatementExportStatus.loaded,
      StatementExportStatus.loading,
      StatementExportStatus.failure
    ]);
    expect(
        remote.attachmentName(
            Response(requestOptions: RequestOptions(path: '/'))),
        'Riwayat_Aktivitas.pdf');
  });

  test('a disposed statement cubit ignores a pending export result', () async {
    final useCases = _UseCases();
    final pending = Completer<Either<NetworkException, StatementExport>>();
    when(() => useCases.exportPdf('m')).thenAnswer((_) => pending.future);
    final cubit = StatementExportCubit(useCases);
    final result = cubit.export('m');
    await cubit.close();
    pending
        .complete(const Right(StatementExport(bytes: [1], filename: 'a.pdf')));
    expect(await result, isNull);
    expect(cubit.state.status, StatementExportStatus.loading);
  });

  test('preview adapter preserves PDF bytes and maps both error kinds',
      () async {
    final source = _Nasabah();
    final repo = PreviewRiwayatRepository(source);
    when(() => source.exportPdf('m')).thenAnswer((_) async =>
        const NasabahExport(bytes: [1, 2], filename: 'preview.pdf'));
    final result = (await repo.exportPdf('m'))
        .getOrElse(() => throw StateError('PDF failed'));
    expect(result.bytes, Uint8List.fromList([1, 2]));
    expect(result.filename, 'preview.pdf');
    when(() => source.history('m', page: 1))
        .thenThrow(NasabahApiException('Pilih bank'));
    expect(
        (await repo.history('m'))
            .swap()
            .getOrElse(() => throw StateError('expected failure'))
            .message,
        'Pilih bank');
    when(() => source.setoranDetail('m', 'tx'))
        .thenThrow(StateError('offline'));
    expect((await repo.setoranDetail('m', 'tx')).isLeft(), isTrue);
    final offline = PreviewNasabahRepository();
    expect(() => offline.exportPdf('m'), throwsUnsupportedError);
  });

  test('history state copies retain omitted fields and explicitly clear errors',
      () {
    const initial = RiwayatHistoryState(
        status: RiwayatHistoryStatus.failure,
        page: 3,
        hasNext: true,
        error: 'offline');
    expect(initial.copyWith(), initial);
    final copy = initial.copyWith(error: null);
    expect(copy.status, RiwayatHistoryStatus.failure);
    expect(copy.page, 3);
    expect(copy.hasNext, isTrue);
    expect(copy.error, isNull);
  });
}
