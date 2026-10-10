import 'dart:async';

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

    test('an item can override the general potongan and be reset', () {
      final editor = _newEditor()
        ..setPotonganDefault(const Potongan(PotonganJenis.persen, 10))
        ..setItemPotongan('n-2', const Potongan(PotonganJenis.rupiah, 500))
        ..setItemNominal('n-3', 100000);
      final state = editor.state;

      expect(state.potonganEfektif(state.items[1]), 500);
      expect(state.potonganEfektif(state.items[2]), 10000);
      expect(state.items.map(state.disesuaikan), [false, true, true]);

      editor.resetItem('n-2');
      editor.resetItem('n-3');

      expect(editor.state.items[1].potongan, isNull);
      expect(editor.state.items[2].nominal, 250000);
      expect(editor.state.items.map(editor.state.disesuaikan),
          [false, false, false]);
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
}) =>
    DraftPencairan(
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
}
