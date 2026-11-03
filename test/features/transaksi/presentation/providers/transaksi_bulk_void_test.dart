import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/bulk_void_result.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/batalkan_beberapa_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/batalkan_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/transaksi_provider.dart';
import '../../../../support/stub_api.dart';
import '../../../../support/transaksi_support.dart';

class _Void extends Mock implements BatalkanTransaksiUseCase {}

TransaksiDetailEntity _detail({bool voided = true}) => TransaksiDetailEntity(
      name: 'Demo',
      amountFormatted: 'Rp 6.000',
      balanceFormatted: 'Rp 0',
      waStatus: '',
      items: [],
      isDibatalkan: voided,
    );

void main() {
  late _Void single;
  late BatalkanBeberapaTransaksiUseCase bulk;
  setUpAll(() => registerFallbackValue(
      TransaksiBatalRequest(id: 'fallback', alasan: 'fallback')));
  setUp(() {
    single = _Void();
    bulk = BatalkanBeberapaTransaksiUseCase(single);
  });

  test('deduplicates choices, trims reason and waits for each existing void',
      () async {
    final first = Completer<Either<NetworkException, TransaksiDetailEntity>>();
    final requests = <TransaksiBatalRequest>[];
    when(() => single.execute(any())).thenAnswer((call) {
      requests.add(call.positionalArguments.first as TransaksiBatalRequest);
      return requests.length == 1
          ? first.future
          : Future.value(Right(_detail()));
    });
    final progress = <String>[];
    final ids = ['s1', 's1', 's2'];
    final pending = bulk.execute(
        ids: ids,
        alasan: '  Salah catat  ',
        canContinue: () => true,
        onProgress: (done, total) => progress.add('$done/$total'));
    await Future<void>.delayed(Duration.zero);
    expect(requests.map((r) => r.id), ['s1']);
    ids.add('not-confirmed');
    first.complete(Right(_detail()));
    final result = await pending;
    expect(requests.map((r) => r.id), ['s1', 's2']);
    expect(requests.every((r) => r.alasan == 'Salah catat'), isTrue);
    expect(result.berhasil, 2);
    expect(result.remainingIds, isEmpty);
    expect(progress, ['1/2', '2/2']);
  });

  for (final reason in ['', '   ', List.filled(256, 'x').join()]) {
    test(
        'rejects invalid reason without any server write (${reason.length} chars)',
        () async {
      final result = await bulk
          .execute(ids: ['s1'], alasan: reason, canContinue: () => true);
      expect(result.berhasil, 0);
      expect(result.outcomes.single.status, BulkVoidStatus.gagal);
      verifyNever(() => single.execute(any()));
    });
  }

  test('counts unicode code points like the backend, not UTF-16 units',
      () async {
    when(() => single.execute(any())).thenAnswer((_) async => Right(_detail()));
    final result = await bulk.execute(
        ids: ['s1'],
        alasan: List.filled(255, '😀').join(),
        canContinue: () => true);
    expect(result.berhasil, 1);
  });

  test('empty batch sends nothing', () async {
    final result = await bulk
        .execute(ids: [], alasan: 'Salah catat', canContinue: () => true);
    expect(result.outcomes, isEmpty);
    verifyNever(() => single.execute(any()));
  });

  test('stopping the caller after first success skips remaining records',
      () async {
    var active = true;
    when(() => single.execute(any())).thenAnswer((_) async {
      active = false;
      return Right(_detail());
    });
    final result = await bulk.execute(
        ids: ['s1', 's2'], alasan: 'Salah catat', canContinue: () => active);
    expect(result.outcomes.map((o) => o.status),
        [BulkVoidStatus.berhasil, BulkVoidStatus.belumDiproses]);
    verify(() => single.execute(any())).called(1);
  });

  test('stopped caller before submission sends nothing', () async {
    final result = await bulk
        .execute(ids: ['s1'], alasan: 'Salah catat', canContinue: () => false);
    expect(result.outcomes.single.status, BulkVoidStatus.belumDiproses);
    verifyNever(() => single.execute(any()));
  });

  for (final status in [401, 403, 429, 500]) {
    test('HTTP $status stops remaining writes', () async {
      when(() => single.execute(any())).thenAnswer((_) async => Left(
          NetworkException(
              message: 'Demo server error',
              response: Response(
                  requestOptions: RequestOptions(), statusCode: status))));
      final result = await bulk.execute(
          ids: ['s1', 's2'], alasan: 'Salah catat', canContinue: () => true);
      expect(
          result.outcomes.first.status,
          status >= 500
              ? BulkVoidStatus.belumDipastikan
              : BulkVoidStatus.gagal);
      expect(result.outcomes.last.status, BulkVoidStatus.belumDiproses);
      expect(result.remainingIds, {'s1', 's2'});
      if (status == 429) {
        expect(result.outcomes.last.message, contains('Batas permintaan'));
      }
      verify(() => single.execute(any())).called(1);
    });
  }

  test('known per-record refusal continues and keeps its original reason',
      () async {
    var calls = 0;
    when(() => single.execute(any())).thenAnswer((_) async => ++calls == 1
        ? Left(NetworkException(
            message: 'Setoran sudah dibatalkan',
            response:
                Response(requestOptions: RequestOptions(), statusCode: 409)))
        : Right(_detail()));
    final result = await bulk.execute(
        ids: ['s1', 's2'], alasan: 'Salah catat', canContinue: () => true);
    expect(result.outcomes.first.message, 'Setoran sudah dibatalkan');
    expect(result.berhasil, 1);
    expect(result.remainingIds, {'s1'});
  });

  test('unexpected response status is uncertain and stops remaining writes',
      () async {
    when(() => single.execute(any()))
        .thenAnswer((_) async => Right(_detail(voided: false)));
    final result = await bulk.execute(
        ids: ['s1', 's2'], alasan: 'Salah catat', canContinue: () => true);
    expect(result.outcomes.map((o) => o.status),
        [BulkVoidStatus.belumDipastikan, BulkVoidStatus.belumDiproses]);
  });

  test('unexpected failure never retries a potentially committed write',
      () async {
    when(() => single.execute(any()))
        .thenThrow(StateError('Demo interrupted response'));
    final result = await bulk.execute(
        ids: ['s1', 's2'], alasan: 'Salah catat', canContinue: () => true);
    expect(result.outcomes.map((o) => o.status),
        [BulkVoidStatus.belumDipastikan, BulkVoidStatus.belumDiproses]);
    verify(() => single.execute(any())).called(1);
  });

  test('actual notifier stops the batch when the authenticated token changes',
      () async {
    final api = StubApi();
    api.onRequest('POST', '/api/v1/transaksi/s1/batalkan', json: (_) {
      api.utils.setToken(
          accessToken: 'other-synthetic-session',
          refreshToken: 'other-synthetic-refresh');
      return {'status': 'dibatalkan', 'nasabah_nama': 'Demo', 'items': []};
    });
    final container = ProviderContainer(overrides: [
      transaksiProvider.overrideWith(() => buildTransaksiNotifier(api))
    ]);
    addTearDown(container.dispose);
    final result = await container
        .read(transaksiProvider.notifier)
        .batalkanBeberapaTransaksi(
            ids: ['s1', 's2'], alasan: 'Salah catat', canContinue: () => true);
    expect(api.requests, hasLength(1));
    expect(result.outcomes.last.status, BulkVoidStatus.belumDiproses);
  });
}
