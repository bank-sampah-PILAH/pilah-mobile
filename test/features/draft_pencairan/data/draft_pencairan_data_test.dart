import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
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
      'jumlah_jenis': null,
      'jumlah_nilai': null,
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

  test('confirmDraft and cancelDraft post to their actions', () async {
    api.on('POST', '$_path/d-1/konfirmasi',
        json: draftJson(status: 'dikonfirmasi'));
    api.on('POST', '$_path/d-1/batalkan',
        json: draftJson(status: 'dibatalkan'));
    final useCases = buildDraftPencairanUseCases(api);

    final confirmed = (await useCases.confirmDraft('d-1')).right;
    final cancelled = (await useCases.cancelDraft('d-1')).right;

    expect(confirmed.status, DraftStatus.dikonfirmasi);
    expect(cancelled.status, DraftStatus.dibatalkan);
  });

  test('a stale confirmation surfaces the per-item field errors', () async {
    api.on('POST', '$_path/d-1/konfirmasi', status: 422, json: {
      'errors': {
        'items[1].nominal': ['Saldo nasabah tidak mencukupi'],
      },
    });

    final result = await buildDraftPencairanUseCases(api).confirmDraft('d-1');

    final failure = result.left;
    expect(failure, isA<UnprocessableEntityException>());
    expect(
        (failure as UnprocessableEntityException)
            .fieldError(['items[1].nominal']),
        'Saldo nasabah tidak mencukupi');
  });

  test('a second confirmation is a conflict', () async {
    api.on('POST', '$_path/d-1/konfirmasi',
        status: 409, json: {'error': 'Draft sudah dikonfirmasi'});

    final result = await buildDraftPencairanUseCases(api).confirmDraft('d-1');

    expect(result.left, isA<ConflictException>());
  });

  test('the jumlah applied to everyone is sent with the draft', () async {
    api.on('POST', _path, status: 201, json: draftJson());

    await buildDraftPencairanUseCases(api).createDraft(const DraftInput(
      potonganDefault: Potongan.nol,
      jumlahUmum: JumlahUmum(JumlahJenis.persen, 50),
      items: [
        DraftItemInput(
            nasabahId: 'n-1', nominal: 1000, metode: MetodePencairan.tunai)
      ],
    ));

    expect(api.last.json['jumlah_jenis'], 'persen');
    expect(api.last.json['jumlah_nilai'], 50);
  });

  test('a saved draft brings back the jumlah that was applied', () async {
    api.on('GET', '$_path/d-1',
        json: draftJson(
            extra: {'jumlah_jenis': 'rupiah', 'jumlah_nilai': '75000.00'}));

    final draft =
        (await buildDraftPencairanUseCases(api).getDraft('d-1')).right;

    expect(draft.jumlahUmum, const JumlahUmum(JumlahJenis.rupiah, 75000));
  });

  test('a draft with nothing applied has no jumlah', () async {
    api.on('GET', '$_path/d-1', json: draftJson());

    final draft =
        (await buildDraftPencairanUseCases(api).getDraft('d-1')).right;

    expect(draft.jumlahUmum, isNull);
  });

  test('drafts that differ only in their jumlah are not the same draft',
      () async {
    api.on('GET', '$_path/d-1', json: draftJson());
    api.on('GET', '$_path/d-2',
        json: draftJson(
            extra: {'jumlah_jenis': 'persen', 'jumlah_nilai': '50.00'}));
    final useCases = buildDraftPencairanUseCases(api);

    final tanpa = (await useCases.getDraft('d-1')).right;
    final dengan = (await useCases.getDraft('d-2')).right;

    expect(tanpa, isNot(equals(dengan)));
  });

  test('exportPratinjau posts the draft as sent and downloads the file',
      () async {
    api.onBytes('POST', '$_path/export', [
      37,
      80,
      68,
      70
    ], headers: {
      'content-disposition': ['attachment; filename="PILAH_Draft_baru.pdf"'],
    });

    final export = (await buildDraftPencairanUseCases(api).exportPratinjau(
      const DraftInput(
        nama: 'Belum Disimpan',
        potonganDefault: Potongan(PotonganJenis.persen, 10),
        items: [
          DraftItemInput(
              nasabahId: 'n-1', nominal: 100000, metode: MetodePencairan.tunai)
        ],
      ),
      ExportBerkas.pdf,
    ))
        .right;

    expect(api.last.query, {'berkas': 'pdf'});
    expect(api.last.json['nama'], 'Belum Disimpan');
    expect((api.last.json['items'] as List).single['nasabah_id'], 'n-1');
    expect(export.filename, 'PILAH_Draft_baru.pdf');
    expect(export.bytes, Uint8List.fromList([37, 80, 68, 70]));
  });

  test('exportDraft downloads the file named by the server', () async {
    api.onBytes('GET', '$_path/d-1/export', [
      37,
      80,
      68,
      70
    ], headers: {
      'content-disposition': [
        'attachment; filename="PILAH_Draft_Pencairan_cair.pdf"',
      ],
    });

    final export = (await buildDraftPencairanUseCases(api)
            .exportDraft('d-1', ExportBerkas.pdf))
        .right;

    expect(api.last.query, {'berkas': 'pdf'});
    expect(export.filename, 'PILAH_Draft_Pencairan_cair.pdf');
    expect(export.bytes, Uint8List.fromList([37, 80, 68, 70]));
  });
}
