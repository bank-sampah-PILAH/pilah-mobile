import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/model/draft_pencairan.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/use_cases/draft_pencairan_use_cases.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/blocs/draft_editor_cubit.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/blocs/draft_editor_state.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';

class _MockUseCases extends Mock implements DraftPencairanUseCases {}

const _ahmad =
    Kandidat(id: 'n-1', kode: 'NAS-0001', nama: 'Ahmad Ridwan', saldo: 465600);
const _budi =
    Kandidat(id: 'n-2', kode: 'NAS-0002', nama: 'Budi Santoso', saldo: 50000);
const _citra =
    Kandidat(id: 'n-3', kode: 'NAS-0003', nama: 'Citra Dewi', saldo: 250000);

DraftEditorCubit _newEditor() =>
    DraftEditorCubit(_MockUseCases())..startNew(const [_ahmad, _budi, _citra]);

void main() {
  persistenceTests();
  lifecycleTests();

  group('a new draft', () {
    test(
        'pays out every picked nasabah their whole saldo, in cash, no potongan',
        () {
      final state = _newEditor().state;

      expect(state.items.map((i) => (i.nasabahNama, i.nominal, i.metode)), [
        ('Ahmad Ridwan', 465600, MetodePencairan.tunai),
        ('Budi Santoso', 50000, MetodePencairan.tunai),
        ('Citra Dewi', 250000, MetodePencairan.tunai),
      ]);
      expect(state.potonganDefault, Potongan.nol);
      expect((state.totalNominal, state.totalPotongan, state.totalDibayar),
          (765600, 0, 765600));
      expect(state.draftId, isNull);
      expect(state.status, DraftStatus.draft);
    });

    test('a general percentage potongan applies to every item, rounded down',
        () {
      final editor = _newEditor()
        ..setPotonganDefault(const Potongan(PotonganJenis.persen, 2.5));

      expect(editor.state.potonganEfektif(editor.state.items[0]), 11640);
      expect(editor.state.potonganEfektif(editor.state.items[1]), 1250);
      expect(editor.state.potonganEfektif(editor.state.items[2]), 6250);
      expect(editor.state.totalPotongan, 19140);
      expect(editor.state.totalDibayar, 765600 - 19140);
    });

    test('a rupiah potongan is taken from every item', () {
      final editor = _newEditor()
        ..setPotonganDefault(const Potongan(PotonganJenis.rupiah, 1000));

      expect(editor.state.totalPotongan, 3000);
    });

    test('an item can override the general potongan and follow it again', () {
      final editor = _newEditor()
        ..setPotonganDefault(const Potongan(PotonganJenis.persen, 10))
        ..setItemPotongan('n-2', const Potongan(PotonganJenis.rupiah, 500))
        ..setItemNominal('n-3', 100000);
      final state = editor.state;

      expect(state.potonganEfektif(state.items[1]), 500);
      expect(state.potonganEfektif(state.items[2]), 10000);
      expect(state.items.map(state.disesuaikan), [false, true, true]);

      editor.setItemPotongan('n-2', null);

      expect(editor.state.items[1].potongan, isNull);
      expect(editor.state.items.map(editor.state.disesuaikan),
          [false, false, true]);
    });

    test('every method can be switched to transfer or cash at once', () {
      final editor = _newEditor()
        ..setItemMetode('n-1', MetodePencairan.transfer)
        ..setMetodeSemua(MetodePencairan.transfer);

      expect(editor.state.items.map((i) => i.metode),
          everyElement(MetodePencairan.transfer));

      editor.setMetodeSemua(MetodePencairan.tunai);

      expect(editor.state.items.map((i) => i.metode),
          everyElement(MetodePencairan.tunai));
    });

    test('an item can be removed, and the totals follow', () {
      final editor = _newEditor()..removeItem('n-1');

      expect(editor.state.items.map((i) => i.nasabahId), ['n-2', 'n-3']);
      expect(editor.state.totalNominal, 300000);
    });
  });

  group('validation', () {
    test('a nominal above the saldo or not above zero is flagged', () {
      final editor = _newEditor()
        ..setItemNominal('n-2', 50001)
        ..setItemNominal('n-3', 0);
      final state = editor.state;

      expect(state.errorFor(state.items[0]), isNull);
      expect(state.errorFor(state.items[1]), contains('saldo'));
      expect(state.errorFor(state.items[2]), contains('nol'));
      expect(state.canSave, isFalse);
    });

    test('a potongan above the nominal or a percentage above 100 is flagged',
        () {
      final editor = _newEditor()
        ..setItemPotongan('n-2', const Potongan(PotonganJenis.rupiah, 50001))
        ..setItemPotongan('n-3', const Potongan(PotonganJenis.persen, 101));
      final state = editor.state;

      expect(state.errorFor(state.items[1]), contains('Potongan'));
      expect(state.errorFor(state.items[2]), contains('100'));
      expect(state.canSave, isFalse);
    });

    test('a general potongan that overruns a small item flags that item', () {
      final editor = _newEditor()
        ..setPotonganDefault(const Potongan(PotonganJenis.rupiah, 60000));

      expect(
          editor.state.errorFor(editor.state.items[1]), contains('Potongan'));
      expect(editor.state.errorFor(editor.state.items[0]), isNull);
    });

    test('a draft with no items cannot be saved', () {
      final editor = DraftEditorCubit(_MockUseCases())..startNew(const []);

      expect(editor.state.canSave, isFalse);
    });
  });
}

DraftPencairan _serverDraft({
  String id = 'd-1',
  DraftStatus status = DraftStatus.draft,
  String nama = 'Cair Oktober',
  List<DraftItem>? items,
  JumlahUmum? jumlah,
}) =>
    DraftPencairan(
      jumlahUmum: jumlah,
      id: id,
      nama: nama,
      status: status,
      potonganDefault: const Potongan(PotonganJenis.persen, 10),
      dibuatOlehNama: 'Ibu Sari',
      diubahOlehNama: 'Pak Budi',
      createdAt: DateTime(2026, 10, 7, 10),
      updatedAt: DateTime(2026, 10, 7, 11),
      items: items ??
          const [
            DraftItem(
              id: 'i-1',
              nasabahId: 'n-1',
              nasabahNama: 'Ahmad Ridwan',
              nominal: 100000,
              metode: MetodePencairan.transfer,
              potonganEfektif: 10000,
              dibayar: 90000,
              saldoSaatIni: 465600,
            ),
            DraftItem(
              id: 'i-2',
              nasabahId: 'n-2',
              nasabahNama: 'Budi Santoso',
              nominal: 50000,
              metode: MetodePencairan.tunai,
              potongan: Potongan(PotonganJenis.rupiah, 1500),
              potonganEfektif: 1500,
              dibayar: 48500,
              saldoSaatIni: 50000,
            ),
          ],
      totalNominal: 150000,
      totalPotongan: 11500,
      totalDibayar: 138500,
    );

UnprocessableEntityException _unprocessable(Map<String, List<String>> errors) =>
    UnprocessableEntityException(
      message: errors.values.first.first,
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: '/api/v1/draft-pencairan'),
        statusCode: 422,
        data: {'errors': errors},
      ),
    );

void persistenceTests() {
  late _MockUseCases useCases;
  late DraftEditorCubit editor;

  setUpAll(() {
    registerFallbackValue(
        const DraftInput(potonganDefault: Potongan.nol, items: []));
    registerFallbackValue(ExportBerkas.pdf);
  });

  setUp(() {
    useCases = _MockUseCases();
    editor = DraftEditorCubit(useCases)
      ..startNew(const [_ahmad, _budi])
      ..setNama('Cair Oktober')
      ..setPotonganDefault(const Potongan(PotonganJenis.persen, 10))
      ..setItemNominal('n-1', 100000)
      ..setItemMetode('n-1', MetodePencairan.transfer)
      ..setItemPotongan('n-2', const Potongan(PotonganJenis.rupiah, 1500));
  });

  group('saving', () {
    test('a new draft is created from the whole editor state', () async {
      when(() => useCases.createDraft(any()))
          .thenAnswer((_) async => Right(_serverDraft()));

      await editor.save();

      final input = verify(() => useCases.createDraft(captureAny()))
          .captured
          .single as DraftInput;
      expect(
          input,
          const DraftInput(
            nama: 'Cair Oktober',
            potonganDefault: Potongan(PotonganJenis.persen, 10),
            items: [
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
          ));
      final state = editor.state;
      expect(state.draftId, 'd-1');
      expect(state.dirty, isFalse);
      expect(state.phase, EditorPhase.idle);
      expect(state.dibuatOlehNama, 'Ibu Sari');
      expect(state.diubahOlehNama, 'Pak Budi');
      expect(
          state.items[1].potongan, const Potongan(PotonganJenis.rupiah, 1500));
    });

    test('a saved draft is updated rather than created again', () async {
      when(() => useCases.createDraft(any()))
          .thenAnswer((_) async => Right(_serverDraft()));
      when(() => useCases.updateDraft(any(), any()))
          .thenAnswer((_) async => Right(_serverDraft(nama: 'Revisi')));
      await editor.save();

      editor.setNama('Revisi');
      expect(editor.state.dirty, isTrue);
      await editor.save();

      verify(() => useCases.updateDraft('d-1', any())).called(1);
      verify(() => useCases.createDraft(any())).called(1);
      expect(editor.state.nama, 'Revisi');
      expect(editor.state.dirty, isFalse);
    });

    test('an edit marks the draft dirty and clears that item\'s server error',
        () async {
      when(() => useCases.createDraft(any()))
          .thenAnswer((_) async => Left(_unprocessable({
                'items[1].nominal': ['Saldo nasabah tidak mencukupi']
              })));
      await editor.save();
      expect(editor.state.itemErrors, {'n-2': 'Saldo nasabah tidak mencukupi'});

      editor.setItemNominal('n-2', 40000);

      expect(editor.state.itemErrors, isEmpty);
      expect(editor.state.dirty, isTrue);
    });

    test('a server rejection of one item is shown on that item', () async {
      when(() => useCases.createDraft(any()))
          .thenAnswer((_) async => Left(_unprocessable({
                'items[1].nominal': ['Saldo nasabah tidak mencukupi']
              })));

      await editor.save();

      final state = editor.state;
      expect(state.itemErrors, {'n-2': 'Saldo nasabah tidak mencukupi'});
      expect(state.errorFor(state.items[1]), 'Saldo nasabah tidak mencukupi');
      expect(state.errorFor(state.items[0]), isNull);
      expect(state.phase, EditorPhase.idle);
      expect(state.dirty, isTrue);
      expect(state.draftId, isNull);
    });

    test('any other failure is reported as a message', () async {
      when(() => useCases.createDraft(any()))
          .thenAnswer((_) async => Left(ConnectionTimeOutException()));

      await editor.save();

      expect(editor.state.errorMessage, isNotNull);
      expect(editor.state.phase, EditorPhase.idle);
    });

    test('nothing is sent while the draft is invalid', () async {
      editor.setItemNominal('n-2', 99999999);

      await editor.save();

      verifyNever(() => useCases.createDraft(any()));
    });

    test('a second tap while saving is ignored', () async {
      final pending = Completer<Either<NetworkException, DraftPencairan>>();
      when(() => useCases.createDraft(any())).thenAnswer((_) => pending.future);

      final first = editor.save();
      await editor.save();
      pending.complete(Right(_serverDraft()));
      await first;

      verify(() => useCases.createDraft(any())).called(1);
    });
  });

  group('loading a saved draft', () {
    test('shows the saved state with the live saldo as the ceiling', () async {
      when(() => useCases.getDraft('d-1'))
          .thenAnswer((_) async => Right(_serverDraft()));
      final fresh = DraftEditorCubit(useCases);

      await fresh.load('d-1');

      final state = fresh.state;
      expect(state.draftId, 'd-1');
      expect(state.nama, 'Cair Oktober');
      expect(state.potonganDefault, const Potongan(PotonganJenis.persen, 10));
      expect(state.items.map((i) => (i.nasabahNama, i.nominal, i.saldo)), [
        ('Ahmad Ridwan', 100000, 465600),
        ('Budi Santoso', 50000, 50000),
      ]);
      expect(state.items[0].potongan, isNull);
      expect(
          state.items[1].potongan, const Potongan(PotonganJenis.rupiah, 1500));
      expect((state.totalNominal, state.totalPotongan, state.totalDibayar),
          (150000, 11500, 138500));
      expect(state.dirty, isFalse);
    });

    test('a nasabah whose saldo dropped below the nominal is flagged',
        () async {
      when(() => useCases.getDraft('d-1'))
          .thenAnswer((_) async => Right(_serverDraft(items: const [
                DraftItem(
                  id: 'i-1',
                  nasabahId: 'n-1',
                  nasabahNama: 'Ahmad Ridwan',
                  nominal: 100000,
                  metode: MetodePencairan.tunai,
                  potonganEfektif: 0,
                  dibayar: 100000,
                  saldoSaatIni: 80000,
                ),
              ])));
      final fresh = DraftEditorCubit(useCases);

      await fresh.load('d-1');

      expect(fresh.state.errorFor(fresh.state.items.single), contains('saldo'));
      expect(fresh.state.canSave, isFalse);
    });

    test('a load that fails says so', () async {
      when(() => useCases.getDraft('d-1'))
          .thenAnswer((_) async => Left(ConnectionTimeOutException()));
      final fresh = DraftEditorCubit(useCases);

      await fresh.load('d-1');

      expect(fresh.state.errorMessage, isNotNull);
      expect(fresh.state.phase, EditorPhase.idle);
      expect(fresh.state.draftId, isNull);
    });
  });
}

void lifecycleTests() {
  late _MockUseCases useCases;
  late DraftEditorCubit editor;

  setUp(() async {
    useCases = _MockUseCases();
    when(() => useCases.getDraft('d-1'))
        .thenAnswer((_) async => Right(_serverDraft()));
    editor = DraftEditorCubit(useCases);
    await editor.load('d-1');
  });

  group('confirming payment', () {
    test('records the payment and locks the draft', () async {
      when(() => useCases.confirmDraft('d-1')).thenAnswer(
          (_) async => Right(_serverDraft(status: DraftStatus.dikonfirmasi)));

      await editor.confirm();

      expect(editor.state.status, DraftStatus.dikonfirmasi);
      expect(editor.state.phase, EditorPhase.idle);
      editor.setNama('Diubah setelah konfirmasi');
      editor.setItemNominal('n-1', 1);
      expect(editor.state.nama, 'Cair Oktober');
      expect(editor.state.items.first.nominal, 100000);
    });

    test('a paid draft shows no complaint about the saldo it just spent',
        () async {
      when(() => useCases.confirmDraft('d-1')).thenAnswer((_) async =>
          Right(_serverDraft(status: DraftStatus.dikonfirmasi, items: const [
            DraftItem(
              id: 'i-1',
              nasabahId: 'n-1',
              nasabahNama: 'Ahmad Ridwan',
              nominal: 100000,
              metode: MetodePencairan.tunai,
              potonganEfektif: 0,
              dibayar: 100000,
              saldoSaatIni: 365600,
            ),
            DraftItem(
              id: 'i-2',
              nasabahId: 'n-2',
              nasabahNama: 'Budi Santoso',
              nominal: 50000,
              metode: MetodePencairan.tunai,
              potonganEfektif: 0,
              dibayar: 50000,
              saldoSaatIni: 0,
            ),
          ])));

      await editor.confirm();

      expect(editor.state.items.map(editor.state.errorFor), [null, null]);
    });

    test('an unsaved draft is saved first and then paid', () async {
      when(() => useCases.createDraft(any()))
          .thenAnswer((_) async => Right(_serverDraft()));
      when(() => useCases.confirmDraft('d-1')).thenAnswer(
          (_) async => Right(_serverDraft(status: DraftStatus.dikonfirmasi)));
      final unsaved = DraftEditorCubit(useCases)..startNew(const [_ahmad]);
      expect(unsaved.state.canConfirm, isTrue);

      await unsaved.confirm();

      verifyInOrder([
        () => useCases.createDraft(any()),
        () => useCases.confirmDraft('d-1'),
      ]);
      expect(unsaved.state.status, DraftStatus.dikonfirmasi);
      expect(unsaved.state.draftId, 'd-1');
    });

    test('unsaved edits are saved before the payment is confirmed', () async {
      when(() => useCases.updateDraft('d-1', any()))
          .thenAnswer((_) async => Right(_serverDraft(nama: 'Baru')));
      when(() => useCases.confirmDraft('d-1')).thenAnswer(
          (_) async => Right(_serverDraft(status: DraftStatus.dikonfirmasi)));
      editor.setNama('Baru');
      expect(editor.state.canConfirm, isTrue);

      await editor.confirm();

      verifyInOrder([
        () => useCases.updateDraft('d-1', any()),
        () => useCases.confirmDraft('d-1'),
      ]);
      expect(editor.state.status, DraftStatus.dikonfirmasi);
    });

    test('a save that fails stops the payment before it starts', () async {
      when(() => useCases.updateDraft('d-1', any()))
          .thenAnswer((_) async => Left(_unprocessable({
                'items[1].nominal': ['Saldo nasabah tidak mencukupi']
              })));
      editor.setNama('Baru');

      await editor.confirm();

      verifyNever(() => useCases.confirmDraft(any()));
      expect(editor.state.itemErrors, {'n-2': 'Saldo nasabah tidak mencukupi'});
      expect(editor.state.status, DraftStatus.draft);
      expect(editor.state.phase, EditorPhase.idle);
    });

    test('an invalid draft cannot be confirmed', () async {
      editor.setItemNominal('n-2', 99999999);

      expect(editor.state.canConfirm, isFalse);
      await editor.confirm();

      verifyNever(() => useCases.updateDraft(any(), any()));
      verifyNever(() => useCases.confirmDraft(any()));
    });

    test('a paid draft cannot be confirmed again', () async {
      when(() => useCases.confirmDraft('d-1')).thenAnswer(
          (_) async => Right(_serverDraft(status: DraftStatus.dikonfirmasi)));
      await editor.confirm();

      expect(editor.state.canConfirm, isFalse);
      await editor.confirm();

      verify(() => useCases.confirmDraft('d-1')).called(1);
    });

    test('a stale saldo is reported on the item and the draft stays open',
        () async {
      when(() => useCases.confirmDraft('d-1'))
          .thenAnswer((_) async => Left(_unprocessable({
                'items[1].nominal': ['Saldo nasabah tidak mencukupi']
              })));

      await editor.confirm();

      expect(editor.state.itemErrors, {'n-2': 'Saldo nasabah tidak mencukupi'});
      expect(editor.state.status, DraftStatus.draft);
      expect(editor.state.phase, EditorPhase.idle);
    });

    test('a draft that was already confirmed says so', () async {
      when(() => useCases.confirmDraft('d-1')).thenAnswer((_) async =>
          Left(ConflictException(message: 'Draft sudah dikonfirmasi')));

      await editor.confirm();

      expect(editor.state.errorMessage, 'Draft sudah dikonfirmasi');
      expect(editor.state.status, DraftStatus.draft);
    });

    test('a second tap while confirming is ignored', () async {
      final pending = Completer<Either<NetworkException, DraftPencairan>>();
      when(() => useCases.confirmDraft('d-1'))
          .thenAnswer((_) => pending.future);

      final first = editor.confirm();
      await editor.confirm();
      pending.complete(Right(_serverDraft(status: DraftStatus.dikonfirmasi)));
      await first;

      verify(() => useCases.confirmDraft('d-1')).called(1);
    });
  });

  group('cancelling', () {
    test('marks the draft cancelled and locks it', () async {
      when(() => useCases.cancelDraft('d-1')).thenAnswer(
          (_) async => Right(_serverDraft(status: DraftStatus.dibatalkan)));

      await editor.cancel();

      expect(editor.state.status, DraftStatus.dibatalkan);
      editor.setNama('Nope');
      expect(editor.state.nama, 'Cair Oktober');
    });

    test('a failure leaves the draft open and says why', () async {
      when(() => useCases.cancelDraft('d-1')).thenAnswer((_) async =>
          Left(ConflictException(message: 'Draft sudah dikonfirmasi')));

      await editor.cancel();

      expect(editor.state.status, DraftStatus.draft);
      expect(editor.state.errorMessage, 'Draft sudah dikonfirmasi');
    });
  });

  group('exporting', () {
    test('hands back the file for a saved draft', () async {
      final file = DraftExport(bytes: Uint8List(3), filename: 'draft.pdf');
      when(() => useCases.exportDraft('d-1', ExportBerkas.pdf))
          .thenAnswer((_) async => Right(file));

      final result = await editor.export(ExportBerkas.pdf);

      expect(result, same(file));
      expect(editor.state.phase, EditorPhase.idle);
    });

    test('a confirmed draft can still be exported', () async {
      when(() => useCases.confirmDraft('d-1')).thenAnswer(
          (_) async => Right(_serverDraft(status: DraftStatus.dikonfirmasi)));
      when(() => useCases.exportDraft('d-1', ExportBerkas.xlsx)).thenAnswer(
          (_) async =>
              Right(DraftExport(bytes: Uint8List(1), filename: 'a.xlsx')));
      await editor.confirm();

      expect(editor.state.canExport, isTrue);
      expect(await editor.export(ExportBerkas.xlsx), isNotNull);
    });

    DraftEditorCubit baruDenganMock() =>
        DraftEditorCubit(useCases)..startNew(const [_ahmad, _budi, _citra]);

    test('unsaved edits are exported as they stand, and stay unsaved',
        () async {
      final file = DraftExport(bytes: Uint8List(2), filename: 'baru.pdf');
      when(() => useCases.exportPratinjau(any(), ExportBerkas.pdf))
          .thenAnswer((_) async => Right(file));
      editor.setNama('Baru');

      expect(editor.state.canExport, isTrue);
      final result = await editor.export(ExportBerkas.pdf);

      expect(result, same(file));
      final input =
          verify(() => useCases.exportPratinjau(captureAny(), ExportBerkas.pdf))
              .captured
              .single as DraftInput;
      expect(input.nama, 'Baru');
      verifyNever(() => useCases.exportDraft(any(), any()));
      verifyNever(() => useCases.updateDraft(any(), any()));
      expect(editor.state.dirty, isTrue);
      expect(editor.state.phase, EditorPhase.idle);
    });

    test('a draft never saved can be exported too', () async {
      when(() => useCases.exportPratinjau(any(), ExportBerkas.xlsx)).thenAnswer(
          (_) async =>
              Right(DraftExport(bytes: Uint8List(1), filename: 'x.xlsx')));
      final baru = baruDenganMock();

      expect(baru.state.draftId, isNull);
      expect(baru.state.canExport, isTrue);
      expect(await baru.export(ExportBerkas.xlsx), isNotNull);
      verifyNever(() => useCases.createDraft(any()));
    });

    test('an edit that cannot be built is not exported', () async {
      final baru = baruDenganMock()..setItemNominal('n-1', 999999999);

      expect(baru.state.canExport, isFalse);
      expect(await baru.export(ExportBerkas.pdf), isNull);
      verifyNever(() => useCases.exportPratinjau(any(), any()));
    });

    test('nothing to export while an export or save is under way', () async {
      final baru = baruDenganMock();
      when(() => useCases.exportPratinjau(any(), any())).thenAnswer(
          (_) => Completer<Either<NetworkException, DraftExport>>().future);

      unawaited(baru.export(ExportBerkas.pdf));
      await Future<void>.delayed(Duration.zero);

      expect(baru.state.phase, EditorPhase.exporting);
      expect(baru.state.canExport, isFalse);
    });

    test('a rejected pratinjau shows its reason and leaves the editor idle',
        () async {
      when(() => useCases.exportPratinjau(any(), any()))
          .thenAnswer((_) async => Left(ConnectionTimeOutException()));
      final baru = baruDenganMock();

      expect(await baru.export(ExportBerkas.pdf), isNull);
      expect(baru.state.errorMessage, isNotNull);
      expect(baru.state.phase, EditorPhase.idle);
    });

    test('a failed download reports a message and returns nothing', () async {
      when(() => useCases.exportDraft('d-1', ExportBerkas.pdf))
          .thenAnswer((_) async => Left(ConnectionTimeOutException()));

      expect(await editor.export(ExportBerkas.pdf), isNull);
      expect(editor.state.errorMessage, isNotNull);
      expect(editor.state.phase, EditorPhase.idle);
    });
  });

  group('naming and the jumlah applied to everyone', () {
    test('a new draft is named at once with the date and time', () {
      final editor = DraftEditorCubit(useCases)
        ..startNew(const [
          Kandidat(id: 'n-1', kode: 'K1', nama: 'Ahmad', saldo: 1000),
        ], sekarang: DateTime(2026, 10, 8, 6, 4));

      expect(editor.state.nama, 'Pencairan 8 Okt 2026, 06:04');
      expect(editor.state.dirty, isFalse);
    });

    test('the name can still be changed', () {
      final editor = DraftEditorCubit(useCases)
        ..startNew(const [_ahmad, _budi, _citra])
        ..setNama('Cair Lebaran');

      expect(editor.state.nama, 'Cair Lebaran');
    });

    test('applying a jumlah keeps it, and it is saved with the draft',
        () async {
      when(() => useCases.createDraft(any()))
          .thenAnswer((_) async => Right(_serverDraft()));
      final editor = DraftEditorCubit(useCases)
        ..startNew(const [_ahmad, _budi, _citra])
        ..terapkanUmum(jumlah: const JumlahUmum(JumlahJenis.persen, 50));

      expect(editor.state.jumlahUmum, const JumlahUmum(JumlahJenis.persen, 50));
      await editor.save();

      final input = verify(() => useCases.createDraft(captureAny()))
          .captured
          .single as DraftInput;
      expect(input.jumlahUmum, const JumlahUmum(JumlahJenis.persen, 50));
    });

    test('applying only a method or potongan leaves the jumlah alone', () {
      final editor = DraftEditorCubit(useCases)
        ..startNew(const [_ahmad, _budi, _citra])
        ..terapkanUmum(jumlah: const JumlahUmum(JumlahJenis.rupiah, 75000))
        ..terapkanUmum(metode: MetodePencairan.transfer);

      expect(
          editor.state.jumlahUmum, const JumlahUmum(JumlahJenis.rupiah, 75000));
    });

    test('a loaded draft brings its jumlah back', () async {
      when(() => useCases.getDraft('d-1')).thenAnswer((_) async => Right(
          _serverDraft(jumlah: const JumlahUmum(JumlahJenis.persen, 25))));
      final editor = DraftEditorCubit(useCases);

      await editor.load('d-1');

      expect(editor.state.jumlahUmum, const JumlahUmum(JumlahJenis.persen, 25));
    });
  });
}
