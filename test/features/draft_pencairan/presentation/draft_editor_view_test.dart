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
import 'package:pilah_mobile/features/draft_pencairan/presentation/pages/draft_editor_page.dart';
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
      await tester.pump();

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

      expect(find.text('Terapkan'), findsOneWidget);
    });

    testWidgets('a potongan shows as a minus, with no umum or khusus tag',
        (tester) async {
      await pumpNew(tester);
      await tester.enterText(find.byKey(const Key('potongan-nilai')), '10');
      await tester.pump();

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
      await tester.pump();

      expect(find.text('\u2212 Rp 76.560'), findsWidgets);
      expect(find.text('Rp 689.040'), findsWidgets);
    });

    testWidgets('the slider sets the percentage too', (tester) async {
      await pumpNew(tester);

      tester
          .widget<Slider>(find.byKey(const Key('potongan-slider')))
          .onChanged!(25);
      await tester.pump();
      await tester.pump();

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
      await tester.pump();

      expect(cubit.state.potonganDefault,
          const Potongan(PotonganJenis.rupiah, 1000));
      expect(find.text('\u2212 Rp 3.000'), findsWidgets);
    });

    testWidgets('one tap sets every method', (tester) async {
      await pumpNew(tester);

      await tester.tap(find.byKey(const Key('metode-semua-transfer')));
      await tester.pump();
      expect(cubit.state.items.map((i) => i.metode),
          everyElement(MetodePencairan.transfer));

      await tester.tap(find.byKey(const Key('metode-semua-tunai')));
      await tester.pump();
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
      await tester.pump();

      await tester.ensureVisible(find.byKey(const Key('potongan-item-n-2')));
      await tester.tap(find.byKey(const Key('potongan-item-n-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('item-potongan-rupiah')));
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('item-potongan-nilai')), '500');
      await tester.tap(find.text('Terapkan'));
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

      final terapkan =
          tester.getRect(find.widgetWithText(ElevatedButton, 'Terapkan'));
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

      expect(find.text('Persen'), findsOneWidget);
      expect(find.text('Nominal'), findsOneWidget);
      expect(find.text('Rupiah'), findsNothing);

      await tester.ensureVisible(find.byKey(const Key('potongan-item-n-2')));
      await tester.tap(find.byKey(const Key('potongan-item-n-2')));
      await tester.pumpAndSettle();

      expect(find.text('Nominal'), findsNWidgets(2));
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

    testWidgets('cancelling asks first, then drops the draft', (tester) async {
      when(() => useCases.cancelDraft('d-1')).thenAnswer(
          (_) async => Right(_saved(status: DraftStatus.dibatalkan)));
      await pumpSaved(tester);

      await tester.tap(find.byKey(const Key('menu-editor')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batalkan draft'));
      await tester.pumpAndSettle();
      verifyNever(() => useCases.cancelDraft(any()));

      await tester.tap(find.text('Ya, batalkan'));
      await tester.pumpAndSettle();

      verify(() => useCases.cancelDraft('d-1')).called(1);
      expect(cubit.state.status, DraftStatus.dibatalkan);
      expect(find.byKey(const Key('simpan')), findsNothing);
    });

    testWidgets('a paid or cancelled draft cannot be cancelled again',
        (tester) async {
      await pumpSaved(tester, status: DraftStatus.dikonfirmasi);

      expect(find.byKey(const Key('menu-editor')), findsNothing);
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

Future<void> _pump(
  WidgetTester tester, {
  bool pushed = false,
  Size size = const Size(420, 1800),
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
