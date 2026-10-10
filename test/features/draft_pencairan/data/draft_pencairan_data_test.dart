import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/model/draft_pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';

import '../../../support/draft_pencairan_support.dart';
import '../../../support/stub_api.dart';

const _path = '/api/v1/draft-pencairan';

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

  test('getKandidat can ask for nasabah without saldo too, to show them',
      () async {
    api.on('GET', '$_path/kandidat', json: [
      {
        'id': 'n-9',
        'kode': 'NAS-0009',
        'nama': 'Fani Kosong',
        'saldo': '0.00',
      },
    ]);

    final result = await buildDraftPencairanUseCases(api)
        .getKandidat(termasukKosong: true);

    expect(api.last.query, {'ordering': 'nama', 'termasuk_kosong': 'true'});
    final fani = result.getOrElse(() => []).single;
    expect(fani.saldo, 0);
    expect(fani.kosong, isTrue);
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

  test('cancelDraft posts to the cancel action', () async {
    api.on('POST', '$_path/d-1/batalkan',
        json: draftJson(status: 'dibatalkan'));

    final cancelled =
        (await buildDraftPencairanUseCases(api).cancelDraft('d-1')).right;

    expect(cancelled.status, DraftStatus.dibatalkan);
  });
}
