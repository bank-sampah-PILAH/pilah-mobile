import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_primary_button.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/model/draft_pencairan.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/use_cases/draft_pencairan_use_cases.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/blocs/draft_editor_cubit.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/blocs/editor_item_view.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/pages/draft_editor_page.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/widgets/editor_item_card.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/widgets/pencairan_ui.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';

import '../../../support/pump_app.dart';

class _MockUseCases extends Mock implements DraftPencairanUseCases {}

const _ahmad =
    Kandidat(id: 'n-1', kode: 'NAS-0001', nama: 'Ahmad Ridwan', saldo: 465600);
const _budi =
    Kandidat(id: 'n-2', kode: 'NAS-0002', nama: 'Budi Santoso', saldo: 50000);
const _citra =
    Kandidat(id: 'n-3', kode: 'NAS-0003', nama: 'Citra Dewi', saldo: 250000);

DraftPencairan _saved({DraftStatus status = DraftStatus.draft}) =>
    DraftPencairan(
      id: 'd-1',
      nama: 'Cair Oktober',
      status: status,
      potonganDefault: Potongan.nol,
      dibuatOlehNama: 'Ibu Sari',
      diubahOlehNama: 'Pak Budi',
      createdAt: DateTime(2026, 10, 7, 9, 5),
      updatedAt: DateTime(2026, 10, 7, 11, 30),
      items: const [
        DraftItem(
          id: 'i-1',
          nasabahId: 'n-1',
          nasabahNama: 'Ahmad Ridwan',
          nominal: 100000,
          metode: MetodePencairan.transfer,
          potonganEfektif: 0,
          dibayar: 100000,
          saldoSaatIni: 465600,
        ),
        DraftItem(
          id: 'i-2',
          nasabahId: 'n-2',
          nasabahNama: 'Budi Santoso',
          nominal: 50000,
          metode: MetodePencairan.tunai,
          potonganEfektif: 0,
          dibayar: 50000,
          saldoSaatIni: 50000,
        ),
      ],
      totalNominal: 150000,
      totalPotongan: 0,
      totalDibayar: 150000,
    );

void main() {
  late _MockUseCases useCases;
  late DraftEditorCubit cubit;

  setUpAll(() {
    registerFallbackValue(
        const DraftInput(potonganDefault: Potongan.nol, items: []));
  });

  setUp(() => useCases = _MockUseCases());

  Future<void> pumpNew(WidgetTester tester) async {
    cubit = DraftEditorCubit(useCases)..startNew(const [_ahmad, _budi, _citra]);
    _current = cubit;
    await _pump(tester);
  }

  Future<void> pumpSaved(
    WidgetTester tester, {
    DraftStatus status = DraftStatus.draft,
  }) async {
    when(() => useCases.getDraft('d-1'))
        .thenAnswer((_) async => Right(_saved(status: status)));
    cubit = DraftEditorCubit(useCases);
    _current = cubit;
    await cubit.load('d-1');
    await _pump(tester);
  }

  group('a new draft', () {
    testWidgets(
        'looks like the rest of pencairan: back button and labelled sections',
        (tester) async {
      await pumpNew(tester);

      expect(find.byKey(const Key('kembali')), findsOneWidget);
      expect(find.text('Pencairan Baru'), findsOneWidget);
      for (final label in [
        'NAMA PENCAIRAN',
        'UNTUK SEMUA NASABAH',
        'RINGKASAN',
        'NASABAH (3)',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.byType(PencairanSummaryCard), findsOneWidget);
      expect(find.byType(PencairanCard), findsWidgets);
    });

    testWidgets('section headings are dark and field labels a quieter grey',
        (tester) async {
      await pumpNew(tester);

      for (final heading in [
        'NAMA PENCAIRAN',
        'UNTUK SEMUA NASABAH',
        'RINGKASAN',
        'NASABAH (3)',
      ]) {
        final style = tester.widget<Text>(find.text(heading)).style!;
        expect(style.color, Colors.black87, reason: heading);
        expect(style.fontSize, 12, reason: heading);
      }
      for (final label in ['POTONGAN UMUM']) {
        expect(tester.widget<Text>(find.text(label)).style!.color,
            Colors.grey[700],
            reason: label);
      }
      expect(tester.widget<Text>(find.text('NOMINAL').first).style!.color,
          Colors.grey[700]);
    });

    testWidgets('each nasabah card leads with an avatar and the name',
        (tester) async {
      await pumpNew(tester);

      expect(find.byKey(const Key('avatar-n-1')), findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(const Key('avatar-n-1')),
              matching: find.text('AR')),
          findsOneWidget);
      expect(find.text('Ahmad Ridwan'), findsOneWidget);
      expect(find.text('Saldo Rp 465.600'), findsNothing,
          reason: 'the saldo lives in the strip now');
    });

    testWidgets('a nasabah card is white with a soft shadow and no outline',
        (tester) async {
      await pumpNew(tester);

      final box = tester.widget<Container>(find
          .descendant(
              of: find.byKey(const Key('item-n-1')),
              matching: find.byType(Container))
          .first);
      final decoration = box.decoration! as BoxDecoration;
      expect(decoration.color, Colors.white);
      expect(decoration.border, isNull);
      expect(decoration.boxShadow, isNotEmpty);
    });

    testWidgets('the card for all nasabah keeps a 2px green outline',
        (tester) async {
      await pumpNew(tester);

      final box = tester.widget<Container>(find
          .descendant(
              of: find.ancestor(
                  of: find.text('UNTUK SEMUA NASABAH'),
                  matching: find.byType(PencairanCard)),
              matching: find.byType(Container))
          .first);
      final border = (box.decoration! as BoxDecoration).border! as Border;
      expect(border.top.color, AppColors.greenDark);
      expect(border.top.width, 2);
    });

    testWidgets('an invalid card is outlined in red', (tester) async {
      await pumpNew(tester);

      await tester.enterText(find.byKey(const Key('nominal-n-2')), '60000');
      await tester.pump();

      final box = tester.widget<Container>(find
          .descendant(
              of: find.byKey(const Key('item-n-2')),
              matching: find.byType(Container))
          .first);
      final border = (box.decoration! as BoxDecoration).border! as Border;
      expect(border.top.color, Colors.red.shade300);
    });

    testWidgets('Total potongan is yellow with a minus, like on the cards',
        (tester) async {
      await pumpNew(tester);
      expect(tester.widget<Text>(find.byKey(const Key('total-potongan'))).data,
          'Rp 0');

      await tester.enterText(find.byKey(const Key('potongan-nilai')), '10');
      await _terapkanUmum(tester);

      final total =
          tester.widget<Text>(find.byKey(const Key('total-potongan')));
      expect(total.data, '\u2212 Rp 76.560');
      expect(total.style!.color, AppColors.statOrange);
    });

    testWidgets('the strip reads top to bottom: saldo awal, potongan, dibayar',
        (tester) async {
      await pumpNew(tester);

      final saldo = tester.getCenter(find.byKey(const Key('saldo-awal-n-1')));
      final potongan = tester.getCenter(find.byKey(const Key('potongan-n-1')));
      final dibayar = tester.getCenter(find.byKey(const Key('dibayar-n-1')));
      expect(saldo.dy, lessThan(potongan.dy));
      expect(potongan.dy, lessThan(dibayar.dy));
      expect(tester.getTopRight(find.byKey(const Key('saldo-awal-n-1'))).dx,
          tester.getTopRight(find.byKey(const Key('dibayar-n-1'))).dx,
          reason: 'values share the right edge');
      expect(tester.widget<Text>(find.byKey(const Key('saldo-awal-n-1'))).data,
          'Rp 465.600');
      expect(tester.widget<Text>(find.byKey(const Key('potongan-n-1'))).data,
          'Rp 0');
      expect(tester.widget<Text>(find.byKey(const Key('dibayar-n-1'))).data,
          'Rp 465.600');
      expect(
          tester
              .widget<Text>(find.byKey(const Key('dibayar-n-1')))
              .style!
              .fontSize,
          20);
      expect(find.text('Saldo awal'), findsNWidgets(3));
      expect(find.text('Dibayar'), findsNWidgets(3));
    });

    testWidgets('the Dicairkan row appears only for a partial pencairan',
        (tester) async {
      await pumpNew(tester);
      expect(find.byKey(const Key('dicairkan-n-2')), findsNothing);

      await tester.enterText(find.byKey(const Key('nominal-n-2')), '30000');
      await tester.pump();

      expect(tester.widget<Text>(find.byKey(const Key('dicairkan-n-2'))).data,
          'Rp 30.000');
      expect(find.byKey(const Key('dicairkan-n-1')), findsNothing);
      final saldo = tester.getCenter(find.byKey(const Key('saldo-awal-n-2')));
      final dicairkan =
          tester.getCenter(find.byKey(const Key('dicairkan-n-2')));
      final potongan = tester.getCenter(find.byKey(const Key('potongan-n-2')));
      expect(saldo.dy, lessThan(dicairkan.dy));
      expect(dicairkan.dy, lessThan(potongan.dy));
    });

    testWidgets(
        'Edit with a pen opens the potongan editor, in the potongan row',
        (tester) async {
      await pumpNew(tester);

      final edit = find.byKey(const Key('potongan-item-n-2'));
      expect(
          find.descendant(of: edit, matching: find.byIcon(Icons.edit_outlined)),
          findsOneWidget);
      expect(find.descendant(of: edit, matching: find.text('Edit')),
          findsOneWidget);
      expect(find.text('Atur potongan'), findsNothing);
      final pill = tester.widget<Container>(
          find.descendant(of: edit, matching: find.byType(Container)).first);
      expect((pill.decoration! as BoxDecoration).border, isNull,
          reason: 'the Edit button has no outline');
      expect(
          tester.getCenter(edit).dy,
          closeTo(
              tester.getCenter(find.byKey(const Key('potongan-n-2'))).dy, 20));

      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('terapkan-item')), findsOneWidget);
    });

    testWidgets('a potongan shows as a minus, with no umum or khusus tag',
        (tester) async {
      await pumpNew(tester);
      await tester.enterText(find.byKey(const Key('potongan-nilai')), '10');
      await _terapkanUmum(tester);

      expect(tester.widget<Text>(find.byKey(const Key('potongan-n-2'))).data,
          '\u2212 Rp 5.000');
      expect(tester.widget<Text>(find.byKey(const Key('dibayar-n-2'))).data,
          'Rp 45.000');
      expect(find.text('umum'), findsNothing);

      cubit.setItemPotongan('n-2', const Potongan(PotonganJenis.rupiah, 500));
      await tester.pump();
      await tester.pump();

      expect(find.text('khusus'), findsNothing);
      expect(tester.widget<Text>(find.byKey(const Key('potongan-n-2'))).data,
          '\u2212 Rp 500');
    });

    testWidgets(
        'methods are plain pills, and Penuh lights up at the full saldo',
        (tester) async {
      await pumpNew(tester);

      expect(
          find.descendant(
              of: find.byKey(const Key('metode-n-1-tunai')),
              matching: find.byType(Icon)),
          findsNothing);
      expect(
          find.descendant(
              of: find.byKey(const Key('metode-n-1-transfer')),
              matching: find.byType(Icon)),
          findsNothing);
      expect(
          tester
              .widget<PencairanChip>(find.byKey(const Key('penuh-n-2')))
              .selected,
          isTrue);

      await tester.enterText(find.byKey(const Key('nominal-n-2')), '30000');
      await tester.pump();

      expect(
          tester
              .widget<PencairanChip>(find.byKey(const Key('penuh-n-2')))
              .selected,
          isFalse);
    });

    testWidgets('a card\'s menu offers remove, and reset only once adjusted',
        (tester) async {
      await pumpNew(tester);

      await tester.tap(find.byKey(const Key('menu-item-n-2')));
      await tester.pumpAndSettle();
      expect(find.text('Hapus dari draft'), findsOneWidget);
      expect(find.text('Kembalikan ke default'), findsNothing);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('nominal-n-2')), '30000');
      await tester.pump();
      await tester.tap(find.byKey(const Key('menu-item-n-2')));
      await tester.pumpAndSettle();

      expect(find.text('Kembalikan ke default'), findsOneWidget);
    });

    testWidgets('the cards fit a narrow phone, even with big amounts',
        (tester) async {
      cubit = DraftEditorCubit(useCases)
        ..startNew(const [
          Kandidat(
              id: 'n-9',
              kode: 'NAS-9',
              nama: 'Nasabah Besar',
              saldo: 123456789),
        ])
        ..setPotonganDefault(const Potongan(PotonganJenis.persen, 12.5));
      _current = cubit;
      await _pump(tester, size: const Size(320, 1800));

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('potongan-item-n-9')), findsOneWidget);
      expect(find.byKey(const Key('dibayar-n-9')), findsOneWidget);
    });

    testWidgets('shows everyone picked with the totals', (tester) async {
      await pumpNew(tester);

      expect(find.text('Ahmad Ridwan'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Citra Dewi'), findsOneWidget);
      expect(find.byKey(const Key('total-nominal')), findsOneWidget);
      expect(find.text('Rp 765.600'), findsNWidgets(2),
          reason: 'total pencairan and total dibayar');
      expect(find.text('Rp 0'), findsWidgets);
    });

    testWidgets('a percentage potongan applies to everyone, rounded down',
        (tester) async {
      await pumpNew(tester);

      await tester.enterText(find.byKey(const Key('potongan-nilai')), '10');
      await _terapkanUmum(tester);

      expect(find.text('\u2212 Rp 76.560'), findsWidgets);
      expect(find.text('Rp 689.040'), findsWidgets);
    });

    testWidgets('the slider sets the percentage too', (tester) async {
      await pumpNew(tester);

      tester
          .widget<Slider>(find.byKey(const Key('potongan-slider')))
          .onChanged!(25);
      await tester.pump();
      await _terapkanUmum(tester);

      expect(cubit.state.potonganDefault,
          const Potongan(PotonganJenis.persen, 25));
      expect(find.text('\u2212 Rp 191.400'), findsWidgets);
    });

    testWidgets('the slider never shows more than two decimals',
        (tester) async {
      await pumpNew(tester);
      final slider = find.byKey(const Key('potongan-slider'));

      // The slider's own arithmetic drifts: 0.5 steps arrive as 56.99999999999999.
      tester.widget<Slider>(slider).onChanged!(56.99999999999999);
      await tester.pump();
      await tester.pump();
      await _terapkanUmum(tester);

      expect(cubit.state.potonganDefault,
          const Potongan(PotonganJenis.persen, 57));
      expect(
          tester
              .widget<TextField>(find.byKey(const Key('potongan-nilai')))
              .controller!
              .text,
          '57');
      expect(tester.widget<Slider>(slider).label, '57%');

      tester.widget<Slider>(slider).onChanged!(33.333333333);
      await tester.pump();
      await tester.pump();
      await _terapkanUmum(tester);

      expect(cubit.state.potonganDefault.nilai, 33.33);
      expect(
          tester
              .widget<TextField>(find.byKey(const Key('potongan-nilai')))
              .controller!
              .text,
          '33.33');
      expect(tester.widget<Slider>(slider).label, '33.33%');
    });

    testWidgets('switching to rupiah takes a fixed amount off each nasabah',
        (tester) async {
      await pumpNew(tester);

      await tester.tap(find.byKey(const Key('potongan-rupiah')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('potongan-nilai')), '1000');
      await _terapkanUmum(tester);

      expect(cubit.state.potonganDefault,
          const Potongan(PotonganJenis.rupiah, 1000));
      expect(find.text('\u2212 Rp 3.000'), findsWidgets);
    });

    testWidgets('one tap sets every method', (tester) async {
      await pumpNew(tester);

      await tester.tap(find.byKey(const Key('metode-semua-transfer')));
      await _terapkanUmum(tester);
      expect(cubit.state.items.map((i) => i.metode),
          everyElement(MetodePencairan.transfer));

      await tester.tap(find.byKey(const Key('metode-semua-tunai')));
      await _terapkanUmum(tester);
      expect(cubit.state.items.map((i) => i.metode),
          everyElement(MetodePencairan.tunai));
    });

    testWidgets('a nominal can be changed, and "Penuh" restores the saldo',
        (tester) async {
      await pumpNew(tester);

      await tester.enterText(find.byKey(const Key('nominal-n-2')), '30000');
      await tester.pump();
      expect(cubit.state.items[1].nominal, 30000);
      expect(find.text('Disesuaikan'), findsOneWidget);

      await tester.tap(find.byKey(const Key('penuh-n-2')));
      await tester.pump();

      expect(cubit.state.items[1].nominal, 50000);
      expect(find.text('Disesuaikan'), findsNothing);
      expect(
          tester
              .widget<TextField>(find.byKey(const Key('nominal-n-2')))
              .controller!
              .text,
          '50000');
    });

    testWidgets('a nominal above the saldo is flagged and blocks saving',
        (tester) async {
      await pumpNew(tester);

      await tester.enterText(find.byKey(const Key('nominal-n-2')), '60000');
      await tester.pump();

      expect(find.text('Nominal melebihi saldo nasabah'), findsOneWidget);
      expect(
          tester
              .widget<CustomPrimaryButton>(find.byKey(const Key('simpan')))
              .onPressed,
          isNull);
    });

    testWidgets(
        'an item can have its own potongan, and follow the general one again',
        (tester) async {
      await pumpNew(tester);
      await tester.enterText(find.byKey(const Key('potongan-nilai')), '10');
      await _terapkanUmum(tester);

      await tester.ensureVisible(find.byKey(const Key('potongan-item-n-2')));
      await tester.tap(find.byKey(const Key('potongan-item-n-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('item-potongan-rupiah')));
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('item-potongan-nilai')), '500');
      await tester.tap(find.byKey(const Key('terapkan-item')));
      await tester.pumpAndSettle();

      expect(cubit.state.items[1].potongan,
          const Potongan(PotonganJenis.rupiah, 500));
      expect(find.text('Disesuaikan'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('menu-item-n-2')));
      await tester.tap(find.byKey(const Key('menu-item-n-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kembalikan ke default'));
      await tester.pumpAndSettle();

      expect(cubit.state.items[1].potongan, isNull);
      expect(find.text('Disesuaikan'), findsNothing);
    });

    testWidgets('the potongan sheet is white with rounded top corners',
        (tester) async {
      await pumpNew(tester);

      await tester.ensureVisible(find.byKey(const Key('potongan-item-n-2')));
      await tester.tap(find.byKey(const Key('potongan-item-n-2')));
      await tester.pumpAndSettle();

      final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
      expect(sheet.backgroundColor, Colors.white);
      expect(
          sheet.shape,
          const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))));
    });

    testWidgets('Ikuti potongan umum sits to the right of Terapkan',
        (tester) async {
      await pumpNew(tester);

      await tester.ensureVisible(find.byKey(const Key('potongan-item-n-2')));
      await tester.tap(find.byKey(const Key('potongan-item-n-2')));
      await tester.pumpAndSettle();

      final terapkan = tester.getRect(find.byKey(const Key('terapkan-item')));
      final ikuti = tester
          .getRect(find.widgetWithText(TextButton, 'Ikuti potongan umum'));
      expect(terapkan.right, lessThan(ikuti.left));
      expect(terapkan.center.dy, closeTo(ikuti.center.dy, 1));

      await tester.tap(find.text('Ikuti potongan umum'));
      await tester.pumpAndSettle();
      expect(cubit.state.items[1].potongan, isNull);
    });

    testWidgets('the potongan kinds are Persen and Nominal, not Rupiah',
        (tester) async {
      await pumpNew(tester);
      Finder label(String key, String text) =>
          find.descendant(of: find.byKey(Key(key)), matching: find.text(text));

      expect(label('potongan-persen', 'Persen'), findsOneWidget);
      expect(label('potongan-rupiah', 'Nominal'), findsOneWidget);
      expect(find.text('Rupiah'), findsNothing);

      await tester.ensureVisible(find.byKey(const Key('potongan-item-n-2')));
      await tester.tap(find.byKey(const Key('potongan-item-n-2')));
      await tester.pumpAndSettle();

      expect(label('item-potongan-rupiah', 'Nominal'), findsOneWidget);
      expect(find.text('Rupiah'), findsNothing);
    });

    testWidgets('an item can be taken out', (tester) async {
      await pumpNew(tester);

      await tester.ensureVisible(find.byKey(const Key('menu-item-n-3')));
      await tester.tap(find.byKey(const Key('menu-item-n-3')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus dari draft'));
      await tester.pumpAndSettle();

      expect(find.text('Citra Dewi'), findsNothing);
      expect(cubit.state.items, hasLength(2));
    });

    testWidgets('saving creates the draft and shows who made it',
        (tester) async {
      when(() => useCases.createDraft(any()))
          .thenAnswer((_) async => Right(_saved()));
      await pumpNew(tester);

      await tester.enterText(
          find.byKey(const Key('nama-draft')), 'Cair Oktober');
      await tester.tap(find.byKey(const Key('simpan')));
      await tester.pumpAndSettle();

      verify(() => useCases.createDraft(any())).called(1);
      expect(find.textContaining('Ibu Sari'), findsWidgets);
      expect(
          tester
              .widget<CustomPrimaryButton>(find.byKey(const Key('simpan')))
              .onPressed,
          isNull,
          reason: 'nothing left to save');
    });

    testWidgets(
        'the server\'s complaint about one nasabah appears on that nasabah',
        (tester) async {
      when(() => useCases.createDraft(any()))
          .thenAnswer((_) async => Left(UnprocessableEntityException(
                message: 'Saldo nasabah tidak mencukupi',
                response: Response<dynamic>(
                  requestOptions: RequestOptions(path: '/x'),
                  statusCode: 422,
                  data: {
                    'errors': {
                      'items[1].nominal': ['Saldo nasabah tidak mencukupi'],
                    },
                  },
                ),
              )));
      await pumpNew(tester);

      await tester.tap(find.byKey(const Key('simpan')));
      await tester.pumpAndSettle();

      expect(find.text('Saldo nasabah tidak mencukupi'), findsOneWidget);
    });
  });

  group('a saved draft', () {
    testWidgets('shows who made it and when, and its name', (tester) async {
      await pumpSaved(tester);

      expect(
          tester
              .widget<TextField>(find.byKey(const Key('nama-draft')))
              .controller!
              .text,
          'Cair Oktober');
      expect(find.textContaining('Dibuat oleh Ibu Sari'), findsOneWidget);
      expect(find.textContaining('7 Okt 2026, 09:05'), findsOneWidget);
      expect(find.textContaining('Diubah oleh Pak Budi'), findsOneWidget);
      expect(find.textContaining('7 Okt 2026, 11:30'), findsOneWidget);
    });

    testWidgets('the names are dark so they can be read at a glance',
        (tester) async {
      await pumpSaved(tester);

      final spans = (tester
              .widget<Text>(find.textContaining('Dibuat oleh Ibu Sari'))
              .textSpan! as TextSpan)
          .children!
          .cast<TextSpan>();
      expect(spans[1].text, 'Ibu Sari');
      expect(spans[1].style!.color, Colors.black87);
    });

    testWidgets('opening an already cancelled draft does not announce it',
        (tester) async {
      when(() => useCases.getDraft('d-1')).thenAnswer(
          (_) async => Right(_saved(status: DraftStatus.dibatalkan)));
      cubit = DraftEditorCubit(useCases);
      _current = cubit;
      await _pump(tester);

      await cubit.load('d-1');
      await tester.pump();
      await tester.pump();

      expect(find.text('Dibatalkan'), findsWidgets);
      expect(find.text('Draft dibatalkan.'), findsNothing);
    });

    testWidgets('the editor has no menu: cancelling lives on the list',
        (tester) async {
      await pumpSaved(tester);

      expect(find.byKey(const Key('menu-editor')), findsNothing);
    });
  });

  group('the general settings', () {
    Future<void> jumlah(WidgetTester tester, String jenis,
        [String? nilai]) async {
      await tester.ensureVisible(find.byKey(Key('jumlah-$jenis')));
      await tester.tap(find.byKey(Key('jumlah-$jenis')));
      await tester.pump();
      if (nilai != null) {
        await tester.enterText(find.byKey(const Key('jumlah-nilai')), nilai);
        await tester.pump();
      }
    }

    Future<void> potongan(WidgetTester tester, String nilai) async {
      await tester.enterText(find.byKey(const Key('potongan-nilai')), nilai);
      await tester.pump();
    }

    bool terapkanAktif(WidgetTester tester) =>
        tester
            .widget<ElevatedButton>(find.byKey(const Key('terapkan-umum')))
            .onPressed !=
        null;

    PencairanChip chip(WidgetTester tester, String key) =>
        tester.widget<PencairanChip>(find.byKey(Key(key)));

    String? teksJumlah(WidgetTester tester) => tester
        .widgetList<TextField>(find.byKey(const Key('jumlah-nilai')))
        .map((f) => f.controller!.text)
        .firstOrNull;

    testWidgets('Metode, Jumlah pencairan and Potongan umum come in order',
        (tester) async {
      await pumpNew(tester);

      expect(find.text('JUMLAH PENCAIRAN'), findsOneWidget);
      final y = [
        for (final key in [
          'metode-semua-tunai',
          'jumlah-persen',
          'potongan-persen',
          'terapkan-umum',
        ])
          tester.getTopLeft(find.byKey(Key(key))).dy,
      ];
      expect(y, [...y]..sort());
    });

    testWidgets('Terapkan is a slim, full-width button', (tester) async {
      await pumpNew(tester);

      final tombol = tester.getSize(find.byKey(const Key('terapkan-umum')));
      final kartu = tester.getSize(find
          .ancestor(
              of: find.byKey(const Key('terapkan-umum')),
              matching: find.byType(PencairanCard))
          .first);
      expect(tombol.height, lessThanOrEqualTo(40));
      expect(tombol.height, greaterThanOrEqualTo(32));
      expect(tombol.width, greaterThan(kartu.width - 60),
          reason: 'still spans the card');
    });

    testWidgets('Jumlah pencairan offers Persen and Nominal, no Penuh',
        (tester) async {
      await pumpNew(tester);

      final x = [
        for (final j in ['persen', 'rupiah'])
          tester.getTopLeft(find.byKey(Key('jumlah-$j'))).dx,
      ];
      expect(x, [...x]..sort());
      expect(find.byKey(const Key('jumlah-penuh')), findsNothing);
    });

    testWidgets('starts at Persen 100, which is the whole saldo',
        (tester) async {
      await pumpNew(tester);

      expect(chip(tester, 'jumlah-persen').selected, isTrue);
      expect(chip(tester, 'jumlah-rupiah').selected, isFalse);
      expect(teksJumlah(tester), '100');
      expect(terapkanAktif(tester), isFalse);
    });

    testWidgets('with amounts set by hand there is nothing to show yet',
        (tester) async {
      await pumpNew(tester);
      cubit.setItemNominal('n-2', 1000);
      await tester.pump();
      await tester.pump();

      expect(chip(tester, 'jumlah-persen').selected, isFalse);
      expect(chip(tester, 'jumlah-rupiah').selected, isFalse);
      expect(find.byKey(const Key('jumlah-nilai')), findsNothing);
    });

    testWidgets('nothing changes until Terapkan is pressed', (tester) async {
      await pumpNew(tester);
      expect(terapkanAktif(tester), isFalse);
      expect(find.byKey(const Key('belum-diterapkan')), findsNothing);

      await jumlah(tester, 'rupiah', '100000');
      await tester.tap(find.byKey(const Key('metode-semua-transfer')));
      await potongan(tester, '10');

      expect(find.byKey(const Key('belum-diterapkan')), findsOneWidget);
      expect(terapkanAktif(tester), isTrue);
      expect(cubit.state.items.map((i) => i.nominal), [465600, 50000, 250000]);
      expect(cubit.state.items.map((i) => i.metode),
          everyElement(MetodePencairan.tunai));
      expect(cubit.state.potonganDefault, Potongan.nol);
      expect(cubit.state.dirty, isFalse);

      await _terapkanUmum(tester);

      expect(cubit.state.items.map((i) => i.nominal), [100000, 50000, 100000]);
      expect(cubit.state.items.map((i) => i.metode),
          everyElement(MetodePencairan.transfer));
      expect(cubit.state.potonganDefault,
          const Potongan(PotonganJenis.persen, 10));
      expect(find.byKey(const Key('belum-diterapkan')), findsNothing);
      expect(terapkanAktif(tester), isFalse);
    });

    testWidgets('a fixed Nominal never pays above a saldo', (tester) async {
      await pumpNew(tester);

      await jumlah(tester, 'rupiah', '100000');
      await _terapkanUmum(tester);

      expect(cubit.state.items.map((i) => i.nominal), [100000, 50000, 100000]);
      expect(find.text('Bermasalah 0'), findsOneWidget);
    });

    testWidgets('Persen pays that share of each saldo, rounded down',
        (tester) async {
      await pumpNew(tester);

      await jumlah(tester, 'persen', '50');
      await _terapkanUmum(tester);

      expect(cubit.state.items.map((i) => i.nominal), [232800, 25000, 125000]);
      expect(find.text('Rp 382.800'), findsWidgets);
    });

    testWidgets('choosing Persen again brings the whole saldo back',
        (tester) async {
      await pumpNew(tester);
      cubit.setItemNominal('n-1', 1000);
      await tester.pump();
      await tester.pump();

      await jumlah(tester, 'persen');
      expect(teksJumlah(tester), '100', reason: 'it starts at the whole saldo');
      expect(terapkanAktif(tester), isTrue);
      await _terapkanUmum(tester);

      expect(cubit.state.items.map((i) => i.nominal), [465600, 50000, 250000]);
    });

    testWidgets('only what was touched is applied', (tester) async {
      await pumpNew(tester);
      cubit.setItemNominal('n-2', 30000);
      cubit.setItemMetode('n-3', MetodePencairan.transfer);
      await tester.pump();
      await tester.pump();

      await potongan(tester, '10');
      await _terapkanUmum(tester);

      expect(cubit.state.items[1].nominal, 30000,
          reason: 'jumlah was not touched');
      expect(cubit.state.items[2].metode, MetodePencairan.transfer,
          reason: 'metode was not touched');
      expect(cubit.state.potonganDefault,
          const Potongan(PotonganJenis.persen, 10));
    });

    testWidgets('an unusable Jumlah keeps Terapkan off', (tester) async {
      await pumpNew(tester);

      await jumlah(tester, 'rupiah');
      expect(terapkanAktif(tester), isFalse, reason: 'no amount yet');
      await tester.enterText(find.byKey(const Key('jumlah-nilai')), '0');
      await tester.pump();
      expect(terapkanAktif(tester), isFalse);

      await jumlah(tester, 'persen', '101');
      expect(terapkanAktif(tester), isFalse, reason: 'over 100 percent');

      await tester.enterText(find.byKey(const Key('jumlah-nilai')), '99');
      await tester.pump();
      expect(terapkanAktif(tester), isTrue);
    });

    group('the Persen slider', () {
      Slider slider(WidgetTester tester) =>
          tester.widget<Slider>(find.byKey(const Key('jumlah-slider')));

      Future<void> geser(WidgetTester tester, double nilai) async {
        slider(tester).onChanged!(nilai);
        await tester.pump();
        await tester.pump();
      }

      testWidgets('Persen has one, starting at 100; Nominal has none',
          (tester) async {
        await pumpNew(tester);

        expect(slider(tester).value, 100);
        expect(slider(tester).min, 0);
        expect(slider(tester).max, 100);

        await jumlah(tester, 'rupiah');
        expect(find.byKey(const Key('jumlah-slider')), findsNothing);
      });

      testWidgets('moving it sets the share, waiting for Terapkan',
          (tester) async {
        await pumpNew(tester);

        await geser(tester, 50);

        expect(teksJumlah(tester), '50');
        expect(slider(tester).label, '50%');
        expect(terapkanAktif(tester), isTrue);
        expect(
            cubit.state.items.map((i) => i.nominal), [465600, 50000, 250000]);

        await _terapkanUmum(tester);

        expect(
            cubit.state.items.map((i) => i.nominal), [232800, 25000, 125000]);
      });

      testWidgets('typing moves the slider too', (tester) async {
        await pumpNew(tester);

        await tester.enterText(find.byKey(const Key('jumlah-nilai')), '25');
        await tester.pump();

        expect(slider(tester).value, 25);
      });

      testWidgets('it never shows more than two decimals', (tester) async {
        await pumpNew(tester);

        await geser(tester, 56.99999999999999);
        expect(teksJumlah(tester), '57');
        expect(slider(tester).label, '57%');

        await geser(tester, 33.333333333);
        expect(teksJumlah(tester), '33.33');
        expect(slider(tester).label, '33.33%');
      });

      testWidgets('back at 100 is back to what is saved', (tester) async {
        await pumpNew(tester);

        await geser(tester, 50);
        expect(terapkanAktif(tester), isTrue);

        await geser(tester, 100);

        expect(terapkanAktif(tester), isFalse);
        expect(find.byKey(const Key('belum-diterapkan')), findsNothing);
      });

      testWidgets('a typed share above 100 pins the slider and stays unusable',
          (tester) async {
        await pumpNew(tester);

        await tester.enterText(find.byKey(const Key('jumlah-nilai')), '150');
        await tester.pump();

        expect(slider(tester).value, 100);
        expect(terapkanAktif(tester), isFalse);
      });
    });

    group('going back to what is saved', () {
      testWidgets('a method changed and changed back', (tester) async {
        await pumpNew(tester);

        await tester.tap(find.byKey(const Key('metode-semua-transfer')));
        await tester.pump();
        expect(terapkanAktif(tester), isTrue);
        expect(chip(tester, 'metode-semua-transfer').selected, isTrue);

        await tester.tap(find.byKey(const Key('metode-semua-tunai')));
        await tester.pump();

        expect(terapkanAktif(tester), isFalse);
        expect(find.byKey(const Key('belum-diterapkan')), findsNothing);
        expect(chip(tester, 'metode-semua-tunai').selected, isTrue);
      });

      testWidgets('a potongan typed and cleared again', (tester) async {
        await pumpNew(tester);

        await potongan(tester, '10');
        expect(terapkanAktif(tester), isTrue);

        await potongan(tester, '0');

        expect(terapkanAktif(tester), isFalse);
        expect(find.byKey(const Key('belum-diterapkan')), findsNothing);
      });

      testWidgets('a jumlah changed and changed back', (tester) async {
        await pumpNew(tester);

        await jumlah(tester, 'persen', '50');
        expect(terapkanAktif(tester), isTrue);

        await tester.enterText(find.byKey(const Key('jumlah-nilai')), '100');
        await tester.pump();

        expect(terapkanAktif(tester), isFalse);
        expect(find.byKey(const Key('belum-diterapkan')), findsNothing);
      });

      testWidgets('one section back to saved does not hide another',
          (tester) async {
        await pumpNew(tester);
        await tester.tap(find.byKey(const Key('metode-semua-transfer')));
        await potongan(tester, '10');

        await tester.tap(find.byKey(const Key('metode-semua-tunai')));
        await tester.pump();

        expect(terapkanAktif(tester), isTrue, reason: 'the potongan remains');
      });

      testWidgets('what was applied becomes the saved state', (tester) async {
        await pumpNew(tester);
        await jumlah(tester, 'persen', '50');
        await _terapkanUmum(tester);

        expect(terapkanAktif(tester), isFalse);
        expect(chip(tester, 'jumlah-persen').selected, isTrue);
        expect(teksJumlah(tester), '50', reason: 'the form shows what is in');

        await tester.enterText(find.byKey(const Key('jumlah-nilai')), '60');
        await tester.pump();
        expect(terapkanAktif(tester), isTrue);

        await tester.enterText(find.byKey(const Key('jumlah-nilai')), '50');
        await tester.pump();
        expect(terapkanAktif(tester), isFalse,
            reason: 'back to the latest applied, not to 100');
      });

      testWidgets('a method applied becomes the saved state too',
          (tester) async {
        await pumpNew(tester);
        await tester.tap(find.byKey(const Key('metode-semua-transfer')));
        await _terapkanUmum(tester);

        await tester.tap(find.byKey(const Key('metode-semua-tunai')));
        await tester.pump();
        expect(terapkanAktif(tester), isTrue);

        await tester.tap(find.byKey(const Key('metode-semua-transfer')));
        await tester.pump();
        expect(terapkanAktif(tester), isFalse);
      });

      testWidgets('a hand edit on a card makes the saved jumlah unknown',
          (tester) async {
        await pumpNew(tester);
        await jumlah(tester, 'persen', '50');
        await _terapkanUmum(tester);

        cubit.setItemNominal('n-2', 1000);
        await tester.pump();
        await tester.pump();

        expect(chip(tester, 'jumlah-persen').selected, isFalse);
        await jumlah(tester, 'persen');
        expect(terapkanAktif(tester), isTrue,
            reason: 'so the same jumlah can be applied again');
      });
    });
  });

  group('a large draft', () {
    final banyak = [
      for (var i = 1; i <= 300; i++)
        Kandidat(
          id: 'b-$i',
          kode: 'NAS-${i.toString().padLeft(4, '0')}',
          nama: 'Nasabah ${i.toString().padLeft(3, '0')}',
          saldo: 10000 + i,
        ),
    ];

    /// Jumps the form to its end or its start, building what comes into view.
    Future<void> scrollKe(WidgetTester tester, {required bool akhir}) async {
      final position =
          tester.state<ScrollableState>(find.byType(Scrollable).first).position;
      // A lazy list only estimates its length until it has built the end, so
      // keep jumping until the extent stops growing.
      for (var i = 0; i < 6; i++) {
        position.jumpTo(akhir ? position.maxScrollExtent : 0);
        await tester.pump();
      }
    }

    Future<void> pumpBanyak(WidgetTester tester) async {
      cubit = DraftEditorCubit(useCases)..startNew(banyak);
      _current = cubit;
      await _pump(tester);
    }

    testWidgets('only the cards near the screen are built', (tester) async {
      await pumpBanyak(tester);

      expect(find.textContaining('NASABAH (300)'), findsOneWidget);
      expect(find.byType(EditorItemCard), findsWidgets);
      expect(find.byType(EditorItemCard).evaluate().length, lessThan(30),
          reason: '300 cards must not all be built at once');
      expect(find.byKey(const Key('item-b-300')), findsOneWidget,
          reason: 'the biggest dibayar comes first');
      expect(find.byKey(const Key('item-b-1')), findsNothing);
    });

    testWidgets('scrolling down reaches the last nasabah', (tester) async {
      await pumpBanyak(tester);

      await scrollKe(tester, akhir: true);

      expect(find.byKey(const Key('item-b-1')), findsOneWidget,
          reason: 'the smallest dibayar comes last');
      expect(find.byKey(const Key('item-b-300')), findsNothing);
    });

    testWidgets('an edit survives its card scrolling off and back',
        (tester) async {
      await pumpBanyak(tester);
      await tester.enterText(find.byKey(const Key('nominal-b-300')), '7777');
      await tester.pump();

      await scrollKe(tester, akhir: true);
      await scrollKe(tester, akhir: false);

      expect(
          cubit.state.items.firstWhere((i) => i.nasabahId == 'b-300').nominal,
          7777);
      final field =
          tester.widget<TextField>(find.byKey(const Key('nominal-b-300')));
      expect(field.controller!.text, '7777');
    });

    testWidgets('the summary counts every nasabah, built or not',
        (tester) async {
      await pumpBanyak(tester);

      final total = banyak.fold<int>(0, (sum, k) => sum + k.saldo);
      expect(cubit.state.totalNominal, total);
      expect(find.byKey(const Key('total-nominal')), findsOneWidget);
    });
  });

  group('finding nasabah in a big draft', () {
    final banyak = [
      for (var i = 1; i <= 40; i++)
        Kandidat(
          id: 'b-$i',
          kode: 'NAS-${i.toString().padLeft(4, '0')}',
          nama: 'Nasabah ${i.toString().padLeft(3, '0')}',
          saldo: 10000 + i * 100,
        ),
    ];

    Future<void> pumpBanyak(WidgetTester tester) async {
      cubit = DraftEditorCubit(useCases)..startNew(banyak);
      _current = cubit;
      await _pump(tester);
    }

    Future<void> settle(WidgetTester tester) async {
      await tester.pump();
      await tester.pump();
    }

    testWidgets('even a short draft has search, sort and filter',
        (tester) async {
      await pumpNew(tester);

      expect(find.byKey(const Key('cari-nasabah')), findsOneWidget);
      expect(find.byKey(const Key('urutkan-nasabah')), findsOneWidget);
      expect(find.byKey(const Key('filter-item-semua')), findsOneWidget);
    });

    testWidgets('the controls show the search box, sort button and chips',
        (tester) async {
      await pumpBanyak(tester);

      expect(find.byKey(const Key('cari-nasabah')), findsOneWidget);
      expect(find.byKey(const Key('urutkan-nasabah')), findsOneWidget);
      expect(find.text('Semua 40'), findsOneWidget);
      expect(find.text('Tunai 40'), findsOneWidget);
      expect(find.text('Transfer 0'), findsOneWidget);
      expect(find.text('Bermasalah 0'), findsOneWidget,
          reason: 'always there: 0 reads as "everything is fine"');
    });

    testWidgets('searching narrows the list but not the totals',
        (tester) async {
      await pumpBanyak(tester);
      final total = cubit.state.totalNominal;

      await tester.enterText(find.byKey(const Key('cari-nasabah')), '017');
      await settle(tester);

      expect(find.text('NASABAH (1 dari 40)'), findsOneWidget);
      expect(find.byKey(const Key('item-b-17')), findsOneWidget);
      expect(find.byKey(const Key('item-b-1')), findsNothing);
      expect(cubit.state.items, hasLength(40));
      expect(cubit.state.totalNominal, total);
    });

    testWidgets('nothing found says so', (tester) async {
      await pumpBanyak(tester);

      await tester.enterText(find.byKey(const Key('cari-nasabah')), 'zzz');
      await settle(tester);

      expect(find.text('Tidak ada nasabah yang cocok.'), findsOneWidget);
    });

    testWidgets(
        'the chips run Semua, Bermasalah, Transfer, Tunai, Potongan khusus',
        (tester) async {
      await pumpBanyak(tester);
      cubit.setItemNominal('b-3', 0);
      await settle(tester);

      final kiri = [
        for (final f in [
          ItemFilter.semua,
          ItemFilter.bermasalah,
          ItemFilter.transfer,
          ItemFilter.tunai,
          ItemFilter.potonganKhusus,
          ItemFilter.pencairanKhusus,
        ])
          tester.getTopLeft(find.byKey(Key('filter-item-${f.name}'))).dx,
      ];

      expect(kiri, [...kiri]..sort());
      expect(ItemFilter.values.map((f) => f.name), [
        'semua',
        'bermasalah',
        'transfer',
        'tunai',
        'potonganKhusus',
        'pencairanKhusus',
      ]);
    });

    testWidgets('a method chip lists only those paid that way', (tester) async {
      await pumpBanyak(tester);
      cubit.setItemMetode('b-5', MetodePencairan.transfer);
      cubit.setItemMetode('b-9', MetodePencairan.transfer);
      await settle(tester);

      await tester.ensureVisible(find.byKey(const Key('filter-item-transfer')));
      await tester.tap(find.byKey(const Key('filter-item-transfer')));
      await settle(tester);

      expect(find.text('Transfer 2'), findsOneWidget);
      expect(find.text('NASABAH (2 dari 40)'), findsOneWidget);
      expect(find.byKey(const Key('item-b-5')), findsOneWidget);
      expect(find.byKey(const Key('item-b-9')), findsOneWidget);
      expect(find.byKey(const Key('item-b-1')), findsNothing);
    });

    testWidgets('Bermasalah counts what is wrong and finds it', (tester) async {
      await pumpBanyak(tester);

      expect(find.text('Bermasalah 0'), findsOneWidget);
      cubit.setItemNominal('b-30', 0);
      await settle(tester);
      expect(find.text('Bermasalah 1'), findsOneWidget);

      await tester
          .ensureVisible(find.byKey(const Key('filter-item-bermasalah')));
      await tester.tap(find.byKey(const Key('filter-item-bermasalah')));
      await settle(tester);

      expect(find.text('NASABAH (1 dari 40)'), findsOneWidget);
      expect(find.byKey(const Key('item-b-30')), findsOneWidget);

      // Fixed: the list under it empties and the chip goes back to 0.
      cubit.setItemNominal('b-30', 10000);
      await settle(tester);
      expect(find.text('NASABAH (0 dari 40)'), findsOneWidget);
      expect(find.text('Tidak ada nasabah yang cocok.'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('filter-item-semua')));
      expect(find.text('Bermasalah 0'), findsOneWidget);

      await tester.tap(find.byKey(const Key('filter-item-semua')));
      await settle(tester);
      expect(find.text('Bermasalah 0'), findsOneWidget);
      expect(find.text('NASABAH (40)'), findsOneWidget);
    });

    testWidgets('Pencairan khusus lists those not paid out in full',
        (tester) async {
      await pumpBanyak(tester);
      cubit.setItemNominal('b-12', 5000);
      await settle(tester);

      await tester
          .ensureVisible(find.byKey(const Key('filter-item-pencairanKhusus')));
      await tester.tap(find.byKey(const Key('filter-item-pencairanKhusus')));
      await settle(tester);

      expect(find.text('Pencairan khusus 1'), findsOneWidget);
      expect(find.text('NASABAH (1 dari 40)'), findsOneWidget);
      expect(find.byKey(const Key('item-b-12')), findsOneWidget);
    });

    testWidgets('Potongan khusus lists those with their own potongan',
        (tester) async {
      await pumpBanyak(tester);
      cubit.setItemPotongan('b-7', const Potongan(PotonganJenis.persen, 5));
      await settle(tester);

      await tester
          .ensureVisible(find.byKey(const Key('filter-item-potonganKhusus')));
      await tester.tap(find.byKey(const Key('filter-item-potonganKhusus')));
      await settle(tester);

      expect(find.byKey(const Key('item-b-7')), findsOneWidget);
      expect(find.text('NASABAH (1 dari 40)'), findsOneWidget);
    });

    Future<String> pertama(WidgetTester tester) async => tester
        .widgetList<EditorItemCard>(find.byType(EditorItemCard))
        .first
        .item
        .nasabahId;

    testWidgets('starts with the biggest dibayar first', (tester) async {
      await pumpBanyak(tester);

      expect(await pertama(tester), 'b-40');
    });

    testWidgets('the sort menu is a white card listing four fields',
        (tester) async {
      await pumpBanyak(tester);

      await tester.tap(find.byKey(const Key('urutkan-nasabah')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('urut-bermasalah')), findsNothing);
      final posisi = [
        for (final f in ['dibayar', 'nama', 'saldo', 'potongan'])
          tester.getTopLeft(find.byKey(Key('urut-$f'))).dy,
      ];
      expect(posisi, [...posisi]..sort(), reason: 'in that order, top down');
      final menu = tester.widget<Material>(find
          .ancestor(
              of: find.byKey(const Key('urut-nama')),
              matching: find.byType(Material))
          .first);
      expect(menu.color, Colors.white);
      expect(menu.surfaceTintColor, Colors.transparent);
    });

    testWidgets('the menu stays open after a choice, which is applied at once',
        (tester) async {
      await pumpBanyak(tester);
      await tester.tap(find.byKey(const Key('urutkan-nasabah')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('urut-nama')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('urut-saldo')), findsOneWidget,
          reason: 'still open');
      expect(await pertama(tester), 'b-1', reason: 'Nama starts A-Z');

      await tester.tap(find.byKey(const Key('urut-saldo')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('urut-saldo')), findsOneWidget);
      expect(await pertama(tester), 'b-40', reason: 'biggest saldo first');
    });

    testWidgets('choosing the same field again reverses it', (tester) async {
      await pumpBanyak(tester);
      await tester.tap(find.byKey(const Key('urutkan-nasabah')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('urut-dibayar')));
      await tester.pumpAndSettle();
      expect(await pertama(tester), 'b-1', reason: 'dibayar flipped');

      await tester.tap(find.byKey(const Key('urut-dibayar')));
      await tester.pumpAndSettle();
      expect(await pertama(tester), 'b-40', reason: 'and flipped back');
    });

    testWidgets('tapping the sort button again closes the menu',
        (tester) async {
      await pumpBanyak(tester);
      await tester.tap(find.byKey(const Key('urutkan-nasabah')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('urut-nama')), findsOneWidget);

      await tester.tap(find.byKey(const Key('urutkan-nasabah')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('urut-nama')), findsNothing);
    });

    testWidgets('tapping elsewhere closes the menu', (tester) async {
      await pumpBanyak(tester);
      await tester.tap(find.byKey(const Key('urutkan-nasabah')));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(10, 1500));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('urut-nama')), findsNothing);
    });

    testWidgets('typing a nominal does not move the card out from under you',
        (tester) async {
      await pumpBanyak(tester);
      expect(await pertama(tester), 'b-40');

      // Far below every other dibayar: by amount it would drop to the bottom.
      await tester.enterText(find.byKey(const Key('nominal-b-40')), '1');
      await settle(tester);

      expect(await pertama(tester), 'b-40', reason: 'it stays where it was');
      expect(cubit.state.items.firstWhere((i) => i.nasabahId == 'b-40').nominal,
          1);
    });

    testWidgets('choosing a sort again puts the cards in their new order',
        (tester) async {
      await pumpBanyak(tester);
      await tester.enterText(find.byKey(const Key('nominal-b-40')), '1');
      await settle(tester);

      await tester.tap(find.byKey(const Key('urutkan-nasabah')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('urut-dibayar'))); // flips
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('urut-dibayar'))); // flips back
      await tester.pumpAndSettle();

      expect(await pertama(tester), 'b-39',
          reason: 'b-40 now pays almost nothing');
    });

    testWidgets('a removed nasabah leaves the order intact', (tester) async {
      await pumpBanyak(tester);

      cubit.removeItem('b-40');
      await settle(tester);

      expect(await pertama(tester), 'b-39');
      expect(find.text('NASABAH (39)'), findsOneWidget);
    });

    testWidgets('an edit made in a narrowed view is kept', (tester) async {
      await pumpBanyak(tester);
      await tester.enterText(find.byKey(const Key('cari-nasabah')), '017');
      await settle(tester);

      await tester.enterText(find.byKey(const Key('nominal-b-17')), '5000');
      await settle(tester);
      await tester.enterText(find.byKey(const Key('cari-nasabah')), '');
      await settle(tester);

      expect(cubit.state.items.firstWhere((i) => i.nasabahId == 'b-17').nominal,
          5000);
      expect(cubit.state.items, hasLength(40));
      expect(find.text('NASABAH (40)'), findsOneWidget);
    });
  });

  testWidgets('leaving with unsaved edits asks before throwing them away',
      (tester) async {
    cubit = DraftEditorCubit(useCases)..startNew(const [_ahmad]);
    _current = cubit;
    await _pump(tester, pushed: true);
    cubit.setNama('Belum disimpan');
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('kembali')));
    await tester.pumpAndSettle();

    expect(find.text('Buang perubahan?'), findsOneWidget);
    await tester.tap(find.text('Tetap di sini'));
    await tester.pumpAndSettle();
    expect(find.byType(DraftEditorView), findsOneWidget);

    await tester.tap(find.byKey(const Key('kembali')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buang'));
    await tester.pumpAndSettle();
    expect(find.byType(DraftEditorView), findsNothing);
  });
}

DraftEditorCubit? _current;

/// Presses Terapkan on the "Untuk semua nasabah" card.
Future<void> _terapkanUmum(WidgetTester tester) async {
  await tester.pump(); // the choice just made enables the button
  await tester.ensureVisible(find.byKey(const Key('terapkan-umum')));
  await tester.tap(find.byKey(const Key('terapkan-umum')));
  await tester.pump();
  await tester.pump();
}

Future<void> _pump(
  WidgetTester tester, {
  bool pushed = false,
  Size size = const Size(420, 2600),
}) async {
  // The cubit is created by each test; find it through the provider.
  await pumpRouted(
    tester,
    Builder(builder: (context) {
      return const _Host();
    }),
    pushed: pushed,
    size: size,
  );
  await tester.pumpAndSettle();
}

class _Host extends StatelessWidget {
  const _Host();

  @override
  Widget build(BuildContext context) => BlocProvider<DraftEditorCubit>.value(
        value: _current!,
        child: const DraftEditorView(),
      );
}
