import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/model/draft_pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';

import '../../../support/draft_pencairan_support.dart';
import '../../../support/stub_api.dart';

const _path = '/api/v1/draft-pencairan';

/// Serves the draft list in two pages, the first pointing at the second.
class _TwoPages extends StubApi {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await super.fetch(options, requestStream, cancelFuture);
    final second = options.uri.queryParameters['page'] == '2';
    return ResponseBody.fromString(
      jsonEncode({
        'next': second ? null : 'http://api.test$_path?page=2',
        'results': [
          {
            'id': second ? 'd-2' : 'd-1',
            'nama': second ? 'Halaman dua' : 'Halaman satu',
            'status': 'draft',
            'jumlah_item': 1,
            'total_nominal': '1000.00',
            'total_potongan': '0.00',
            'total_dibayar': '1000.00',
          },
        ],
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  late StubApi api;

  setUp(() => api = StubApi());

  test('getKandidat sends the search, sort and minimum saldo and parses rows',
      () async {
    api.on('GET', '$_path/kandidat', json: [
      {
        'id': 'n-1',
        'kode': 'NAS-0001',
        'nama': 'Ahmad Ridwan',
        'saldo': '465600.00',
      },
    ]);

    final result = await buildDraftPencairanUseCases(api).getKandidat(
      search: 'ahm',
      urutan: KandidatUrutan.saldoTerbesar,
      saldoMin: 50000,
    );

    expect(api.last.query,
        {'search': 'ahm', 'ordering': '-saldo', 'saldo_min': '50000'});
    expect(result.getOrElse(() => []), const [
      Kandidat(
          id: 'n-1', kode: 'NAS-0001', nama: 'Ahmad Ridwan', saldo: 465600),
    ]);
  });

  test('getKandidat leaves out an empty search and a zero minimum', () async {
    api.on('GET', '$_path/kandidat', json: []);

    await buildDraftPencairanUseCases(api).getKandidat();

    expect(api.last.query, {'ordering': 'nama'});
  });

  test('createDraft posts the full item list and parses the calculated draft',
      () async {
    api.on('POST', _path, status: 201, json: draftJson());
    final input = DraftInput(
      nama: 'Cair Oktober',
      potonganDefault: const Potongan(PotonganJenis.persen, 10),
      items: const [
        DraftItemInput(
          nasabahId: 'n-1',
          nominal: 100000,
          metode: MetodePencairan.transfer,
        ),
        DraftItemInput(
          nasabahId: 'n-2',
          nominal: 50000,
          metode: MetodePencairan.tunai,
          potongan: Potongan(PotonganJenis.rupiah, 1500),
        ),
      ],
    );

    final draft =
        (await buildDraftPencairanUseCases(api).createDraft(input)).right;

    expect(api.last.json, {
      'nama': 'Cair Oktober',
      'potongan_jenis': 'persen',
      'potongan_nilai': 10,
      'items': [
        {
          'nasabah_id': 'n-1',
          'nominal': 100000,
          'metode': 'transfer',
          'potongan_jenis': null,
          'potongan_nilai': null,
        },
        {
          'nasabah_id': 'n-2',
          'nominal': 50000,
          'metode': 'tunai',
          'potongan_jenis': 'rupiah',
          'potongan_nilai': 1500,
        },
      ],
    });
    expect(draft.id, 'd-1');
    expect(draft.nama, 'Cair Oktober');
    expect(draft.status, DraftStatus.draft);
    expect(draft.potonganDefault, const Potongan(PotonganJenis.persen, 10));
    expect(draft.dibuatOlehNama, 'Ibu Sari');
    expect(draft.diubahOlehNama, 'Pak Budi');
    expect((draft.totalNominal, draft.totalPotongan, draft.totalDibayar),
        (100000, 10000, 90000));
    final item = draft.items.single;
    expect(item.nasabahNama, 'Ahmad Ridwan');
    expect(item.metode, MetodePencairan.transfer);
    expect(item.potongan, isNull, reason: 'blank jenis follows the default');
    expect((item.potonganEfektif, item.dibayar, item.saldoSaatIni),
        (10000, 90000, 465600));
  });

  test('an item with its own potongan is parsed as an override', () async {
    api.on('GET', '$_path/d-1',
        json: draftJson(items: [
          {
            ...draftItemJson,
            'potongan_jenis': 'rupiah',
            'potongan_nilai': '1500.00',
          },
        ]));

    final draft =
        (await buildDraftPencairanUseCases(api).getDraft('d-1')).right;

    expect(draft.items.single.potongan,
        const Potongan(PotonganJenis.rupiah, 1500));
  });

  test('updateDraft patches the draft and clears an override with nulls',
      () async {
    api.on('PATCH', '$_path/d-1', json: draftJson());

    await buildDraftPencairanUseCases(api).updateDraft(
      'd-1',
      const DraftInput(
        nama: 'Revisi',
        potonganDefault: Potongan(PotonganJenis.rupiah, 2000),
        items: [
          DraftItemInput(
            nasabahId: 'n-1',
            nominal: 80000,
            metode: MetodePencairan.tunai,
          ),
        ],
      ),
    );

    expect(api.last.method, 'PATCH');
    expect(api.last.json['potongan_jenis'], 'rupiah');
    expect(api.last.json['items'][0]['potongan_jenis'], isNull);
    expect(api.last.json['items'][0]['potongan_nilai'], isNull);
  });

  test('getDrafts reads every page of summaries', () async {
    api.on('GET', _path, json: {
      'next': null,
      'results': [
        {
          'id': 'd-1',
          'nama': 'Cair Oktober',
          'status': 'dikonfirmasi',
          'dibuat_oleh_nama': 'Ibu Sari',
          'diubah_oleh_nama': 'Pak Budi',
          'created_at': '2026-10-07T03:00:00Z',
          'updated_at': '2026-10-07T04:00:00Z',
          'jumlah_item': 2,
          'total_nominal': '150000.00',
          'total_potongan': '11500.00',
          'total_dibayar': '138500.00',
        },
      ],
    });

    final drafts = (await buildDraftPencairanUseCases(api).getDrafts())
        .getOrElse(() => []);

    expect(drafts.single.status, DraftStatus.dikonfirmasi);
    expect(drafts.single.jumlahItem, 2);
    expect(drafts.single.totalDibayar, 138500);
  });

  test('getDrafts follows the pages until there is no next one', () async {
    final paged = _TwoPages();

    final drafts = (await buildDraftPencairanUseCases(paged).getDrafts()).right;

    expect(drafts.map((d) => d.nama), ['Halaman satu', 'Halaman dua']);
    expect(paged.requests.map((r) => r.query['page']), [null, '2']);
  });

  test('the same draft read twice is equal, whatever it holds', () async {
    api.on('GET', '$_path/d-1', json: draftJson());
    final useCases = buildDraftPencairanUseCases(api);

    final first = (await useCases.getDraft('d-1')).right;
    final second = (await useCases.getDraft('d-1')).right;

    expect(first, second);
    expect(first.items.single, second.items.single);
  });

  test('cancelDraft posts to the cancel action', () async {
    api.on('POST', '$_path/d-1/batalkan',
        json: draftJson(status: 'dibatalkan'));

    final cancelled =
        (await buildDraftPencairanUseCases(api).cancelDraft('d-1')).right;

    expect(cancelled.status, DraftStatus.dibatalkan);
  });

  test('updateDraft sends a cleared name so the server names it again',
      () async {
    api.on('PATCH', '$_path/d-1', json: draftJson());
    const potongan = Potongan(PotonganJenis.persen, 10);
    const item = DraftItemInput(
      nasabahId: 'n-1',
      nominal: 80000,
      metode: MetodePencairan.tunai,
    );

    await buildDraftPencairanUseCases(api).updateDraft(
      'd-1',
      const DraftInput(nama: '  ', potonganDefault: potongan, items: [item]),
    );
    expect(api.last.json, containsPair('nama', ''));

    await buildDraftPencairanUseCases(api).updateDraft(
      'd-1',
      const DraftInput(potonganDefault: potongan, items: [item]),
    );
    expect(api.last.json, isNot(contains('nama')),
        reason: 'no name given keeps the stored one');
  });

  test('a status the app does not know is read as locked, not editable',
      () async {
    api.on('GET', '$_path/d-1', json: draftJson(status: 'diarsipkan'));

    final draft =
        (await buildDraftPencairanUseCases(api).getDraft('d-1')).right;

    expect(draft.status, DraftStatus.tidakDikenal);
    expect(draft.status.terkunci, isTrue);
  });
}
