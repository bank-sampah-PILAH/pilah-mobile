import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_primary_button.dart';
import 'package:pilah_mobile/core/router/root_navigator_key.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/model/draft_pencairan.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/use_cases/draft_pencairan_use_cases.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/blocs/pilih_nasabah_cubit.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/pages/draft_editor_args.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/pages/draft_list_page.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/pages/pilih_nasabah_pencairan_page.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/widgets/pencairan_ui.dart';

class _MockUseCases extends Mock implements DraftPencairanUseCases {}

const _ahmad =
    Kandidat(id: 'n-1', kode: 'NAS-0001', nama: 'Ahmad Ridwan', saldo: 465600);
const _budi =
    Kandidat(id: 'n-2', kode: 'NAS-0002', nama: 'Budi Santoso', saldo: 50000);
const _citra =
    Kandidat(id: 'n-3', kode: 'NAS-0003', nama: 'Citra Dewi', saldo: 250000);
const _fani =
    Kandidat(id: 'n-4', kode: 'NAS-0004', nama: 'Fani Kosong', saldo: 0);

void main() {
  late _MockUseCases useCases;
  Object? openedWith;

  void answer({
    String search = '',
    KandidatUrutan urutan = KandidatUrutan.namaAZ,
    List<Kandidat> rows = const [_ahmad, _budi, _citra, _fani],
  }) {
    when(() => useCases.getKandidat(
          search: search,
          urutan: urutan,
          termasukKosong: true,
        )).thenAnswer((_) async => Right(rows));
  }

  setUp(() {
    useCases = _MockUseCases();
    openedWith = null;
    answer();
  });

  Future<void> pump(WidgetTester tester) async {
    final router = GoRouter(
      navigatorKey: rootNavigatorKey,
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => BlocProvider(
            create: (_) => PilihNasabahCubit(useCases)..load(),
            child: const PilihNasabahView(),
          ),
        ),
        GoRoute(
          path: DraftListPage.routeEditor,
          builder: (_, state) {
            openedWith = state.extra;
            return const Scaffold(body: Text('route:editor'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  testWidgets('has the pencairan header with a back button', (tester) async {
    await pump(tester);

    expect(find.byKey(const Key('kembali')), findsOneWidget);
    expect(find.text('Pilih Nasabah'), findsOneWidget);
    expect(find.byType(PencairanChip), findsWidgets,
        reason: 'the filters are pills');
  });

  testWidgets('every row shows the nasabah\'s avatar', (tester) async {
    await pump(tester);

    for (final id in ['n-1', 'n-2', 'n-3']) {
      expect(find.byKey(Key('avatar-$id')), findsOneWidget, reason: id);
    }
    expect(
        find.descendant(
            of: find.byKey(const Key('avatar-n-2')), matching: find.text('BS')),
        findsOneWidget);
  });

  testWidgets('rows are shadow cards, and a picked row gets a green outline',
      (tester) async {
    await pump(tester);

    BoxDecoration decorationOf(String id) => tester
        .widget<Container>(find
            .descendant(
                of: find.byKey(Key('kandidat-$id')),
                matching: find.byType(Container))
            .first)
        .decoration! as BoxDecoration;

    expect(decorationOf('n-1').border, isNull);
    expect(decorationOf('n-1').boxShadow, isNotEmpty);

    await tester.tap(find.byKey(const Key('kandidat-n-1')));
    await tester.pump();

    final border = decorationOf('n-1').border! as Border;
    expect(border.top.color, AppColors.greenDark);
    expect(border.top.width, 2);
    expect(decorationOf('n-2').border, isNull);
  });

  testWidgets('lists each nasabah with their code and saldo', (tester) async {
    await pump(tester);

    expect(find.text('Ahmad Ridwan'), findsOneWidget);
    expect(find.textContaining('NAS-0002'), findsOneWidget);
    expect(find.textContaining('Rp 250.000'), findsOneWidget);
    expect(find.text('0 dipilih'), findsOneWidget);
  });

  testWidgets('continue stays off until someone is picked', (tester) async {
    await pump(tester);

    expect(
        tester
            .widget<CustomPrimaryButton>(find.byKey(const Key('lanjut')))
            .onPressed,
        isNull);

    await tester.tap(find.byKey(const Key('kandidat-n-2')));
    await tester.pump();

    expect(find.text('1 dipilih'), findsOneWidget);
    expect(find.textContaining('Rp 50.000'), findsWidgets);
    expect(
        tester
            .widget<CustomPrimaryButton>(find.byKey(const Key('lanjut')))
            .onPressed,
        isNotNull);
  });

  testWidgets('continue hands the picked nasabah to the editor',
      (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('kandidat-n-3')));
    await tester.tap(find.byKey(const Key('kandidat-n-1')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('lanjut')));
    await tester.pumpAndSettle();

    expect(find.text('route:editor'), findsOneWidget);
    expect((openedWith! as DraftEditorArgs).kandidat, [_ahmad, _citra]);
  });

  testWidgets('the search field has the sort button beside it, as elsewhere',
      (tester) async {
    await pump(tester);

    expect(find.byKey(const Key('urutkan-kandidat')), findsOneWidget);
    expect(find.byIcon(Icons.swap_vert), findsOneWidget);
    expect(find.byKey(const Key('urutan')), findsNothing,
        reason: 'no sort icon in the header any more');
    final cari = tester.getRect(find.byKey(const Key('cari-kandidat')));
    final urut = tester.getRect(find.byKey(const Key('urutkan-kandidat')));
    expect(urut.left, greaterThanOrEqualTo(cari.right));
    expect((urut.center.dy - cari.center.dy).abs(), lessThan(4));
  });

  testWidgets(
      'the sort menu offers name and saldo, with the arrow on the right',
      (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('urutkan-kandidat')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('urut-kandidat-nama')), findsOneWidget);
    expect(find.byKey(const Key('urut-kandidat-saldo')), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('urut-kandidat-nama')),
            matching: find.byIcon(Icons.arrow_upward)),
        findsOneWidget,
        reason: 'name A to Z is the current order');
  });

  testWidgets('choosing saldo asks the server for the biggest first',
      (tester) async {
    answer(
        urutan: KandidatUrutan.saldoTerbesar,
        rows: const [_ahmad, _citra, _budi]);
    await pump(tester);

    await tester.tap(find.byKey(const Key('urutkan-kandidat')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('urut-kandidat-saldo')));
    await tester.pumpAndSettle();

    verify(() => useCases.getKandidat(
        search: '',
        urutan: KandidatUrutan.saldoTerbesar,
        termasukKosong: true)).called(1);
  });

  group('filter chips', () {
    PencairanChip chip(WidgetTester tester, String key) =>
        tester.widget<PencairanChip>(find.byKey(Key(key)));

    testWidgets('are pills with their counts, Semua green to begin with',
        (tester) async {
      await pump(tester);

      expect(chip(tester, 'pf-semua').selected, isTrue);
      expect(chip(tester, 'pf-semua').count, 4);
      expect(chip(tester, 'pf-terpilih').selected, isFalse);
      expect(chip(tester, 'pf-terpilih').count, 0);
      expect(chip(tester, 'pf-belum').count, 4);
      expect(chip(tester, 'pf-kosong').count, 1);
      expect(find.text('Saldo minimal'), findsOneWidget);
    });

    testWidgets('sit at the left, right under the search field',
        (tester) async {
      await pump(tester);

      final semua = tester.getRect(find.byKey(const Key('pf-semua')));
      final cari = tester.getRect(find.byKey(const Key('cari-kandidat')));
      expect(semua.left, cari.left);
      expect(semua.top - cari.bottom, lessThan(24));
    });

    testWidgets('the tapped one turns green and narrows the list',
        (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('kandidat-n-1')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('pf-terpilih')));
      await tester.pumpAndSettle();

      expect(chip(tester, 'pf-terpilih').selected, isTrue);
      expect(chip(tester, 'pf-semua').selected, isFalse);
      expect(find.byKey(const Key('kandidat-n-1')), findsOneWidget);
      expect(find.byKey(const Key('kandidat-n-2')), findsNothing);
    });

    testWidgets('a minimum saldo asks for the amount, and shows it on the chip',
        (tester) async {
      await pump(tester);

      await tester.ensureVisible(find.byKey(const Key('pf-saldo')));
      await tester.tap(find.byKey(const Key('pf-saldo')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('saldo-min-field')), '200000');
      await tester.tap(find.text('Terapkan'));
      await tester.pumpAndSettle();

      expect(chip(tester, 'pf-saldo').selected, isTrue);
      expect(chip(tester, 'pf-saldo').label, 'Saldo \u2265 Rp 200.000');
      expect(find.byKey(const Key('kandidat-n-2')), findsNothing);
      expect(find.byKey(const Key('kandidat-n-3')), findsOneWidget);
    });

    group('the saldo minimal sheet', () {
      Future<void> open(WidgetTester tester) async {
        await pump(tester);
        await tester.ensureVisible(find.byKey(const Key('pf-saldo')));
        await tester.tap(find.byKey(const Key('pf-saldo')));
        await tester.pumpAndSettle();
      }

      testWidgets('is a white rounded sheet, not a plain dialog',
          (tester) async {
        await open(tester);

        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(BottomSheet), findsOneWidget);
        final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
        expect(sheet.backgroundColor, Colors.white);
        expect(sheet.shape, isA<RoundedRectangleBorder>());
        expect(find.text('Saldo minimal'), findsWidgets);
      });

      testWidgets('offers amounts to pick with one tap', (tester) async {
        await open(tester);

        for (final label in [
          'Rp 100 rb',
          'Rp 250 rb',
          'Rp 500 rb',
          'Rp 1 jt'
        ]) {
          expect(find.text(label), findsOneWidget, reason: label);
        }
      });

      testWidgets('tapping an amount fills the field and turns green',
          (tester) async {
        await open(tester);

        await tester.tap(find.byKey(const Key('saldo-pilihan-250000')));
        await tester.pump();

        expect(
            tester
                .widget<TextField>(find.byKey(const Key('saldo-min-field')))
                .controller!
                .text,
            '250000');
        expect(
            tester
                .widget<PencairanChip>(
                    find.byKey(const Key('saldo-pilihan-250000')))
                .selected,
            isTrue);
        expect(
            tester
                .widget<PencairanChip>(
                    find.byKey(const Key('saldo-pilihan-500000')))
                .selected,
            isFalse);
      });

      testWidgets('says how many nasabah meet the amount, as it is typed',
          (tester) async {
        await open(tester);
        expect(find.byKey(const Key('saldo-pratinjau')), findsOneWidget);
        expect(find.textContaining('3 nasabah memenuhi'), findsNothing,
            reason: 'no amount yet: nothing to preview as a limit');

        await tester.enterText(
            find.byKey(const Key('saldo-min-field')), '250000');
        await tester.pump();

        expect(find.textContaining('2 nasabah memenuhi'), findsOneWidget);
      });

      testWidgets('warns when nobody meets the amount', (tester) async {
        await open(tester);

        await tester.enterText(
            find.byKey(const Key('saldo-min-field')), '9000000');
        await tester.pump();

        expect(find.textContaining('Belum ada nasabah'), findsOneWidget);
      });

      testWidgets('applying hands the amount to the list', (tester) async {
        await open(tester);

        await tester.tap(find.byKey(const Key('saldo-pilihan-250000')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('terapkan-saldo-min')));
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheet), findsNothing);
        expect(find.byKey(const Key('kandidat-n-2')), findsNothing);
        expect(find.byKey(const Key('kandidat-n-3')), findsOneWidget);
      });

      testWidgets('cancelling leaves the list alone', (tester) async {
        await open(tester);

        await tester.tap(find.byKey(const Key('saldo-pilihan-250000')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('batal-saldo-min')));
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheet), findsNothing);
        expect(find.byKey(const Key('kandidat-n-2')), findsOneWidget);
      });
    });

    testWidgets('tapping the active minimum saldo takes it off again',
        (tester) async {
      await pump(tester);
      await tester.ensureVisible(find.byKey(const Key('pf-saldo')));
      await tester.tap(find.byKey(const Key('pf-saldo')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('saldo-min-field')), '200000');
      await tester.tap(find.text('Terapkan'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('pf-saldo')));
      await tester.tap(find.byKey(const Key('pf-saldo')));
      await tester.pumpAndSettle();

      expect(chip(tester, 'pf-saldo').selected, isFalse);
      expect(find.byKey(const Key('kandidat-n-2')), findsOneWidget);
    });

    testWidgets('say so when a filter leaves nobody', (tester) async {
      await pump(tester);

      await tester.tap(find.byKey(const Key('pf-terpilih')));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada nasabah pada filter ini'), findsOneWidget);
    });
  });

  group('nasabah without saldo', () {
    testWidgets('are listed, dimmed, with a label saying why', (tester) async {
      await pump(tester);

      expect(find.byKey(const Key('kandidat-n-4')), findsOneWidget);
      expect(find.text('Saldo kosong'), findsWidgets);
      expect(
          tester
              .widget<Checkbox>(find.descendant(
                  of: find.byKey(const Key('kandidat-n-4')),
                  matching: find.byType(Checkbox)))
              .onChanged,
          isNull,
          reason: 'cannot be ticked');
      expect(
          tester
              .widget<Opacity>(find.descendant(
                  of: find.byKey(const Key('kandidat-n-4')),
                  matching: find.byType(Opacity)))
              .opacity,
          lessThan(1));
    });

    testWidgets('tapping one picks nothing', (tester) async {
      await pump(tester);

      await tester.tap(find.byKey(const Key('kandidat-n-4')));
      await tester.pump();

      expect(find.text('0 dipilih'), findsOneWidget);
    });

    testWidgets('the Saldo kosong chip lists only them', (tester) async {
      await pump(tester);

      await tester.tap(find.byKey(const Key('pf-kosong')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('kandidat-n-4')), findsOneWidget);
      expect(find.byKey(const Key('kandidat-n-1')), findsNothing);
    });
  });

  group('picking in bulk', () {
    testWidgets('the checkbox row picks everyone shown who has saldo',
        (tester) async {
      await pump(tester);

      expect(find.textContaining('Pilih semua'), findsOneWidget);
      await tester.tap(find.byKey(const Key('pilih-tampil')));
      await tester.pumpAndSettle();

      expect(find.text('3 dipilih'), findsOneWidget);
      expect(find.textContaining('Rp 765.600'), findsOneWidget);
    });

    testWidgets('its box is ticked when all are picked, dashed when some are',
        (tester) async {
      await pump(tester);
      Checkbox box() => tester.widget<Checkbox>(find.descendant(
          of: find.byKey(const Key('pilih-tampil')),
          matching: find.byType(Checkbox)));
      expect(box().value, isFalse);

      await tester.tap(find.byKey(const Key('kandidat-n-1')));
      await tester.pump();
      expect(box().value, isNull, reason: 'partial shows as a dash');

      await tester.tap(find.byKey(const Key('pilih-tampil')));
      await tester.pump();
      expect(box().value, isTrue);
    });

    testWidgets('invert and clear change the picks', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('kandidat-n-1')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('balikkan')));
      await tester.pump();
      expect(find.text('2 dipilih'), findsOneWidget);

      await tester.tap(find.byKey(const Key('kosongkan')));
      await tester.pump();
      expect(find.text('0 dipilih'), findsOneWidget);
    });
  });

  testWidgets('searching waits for a pause in typing, then asks the server',
      (tester) async {
    answer(search: 'bud', rows: const [_budi]);
    await pump(tester);

    await tester.enterText(find.byKey(const Key('cari-kandidat')), 'b');
    await tester.enterText(find.byKey(const Key('cari-kandidat')), 'bud');
    await tester.pump(const Duration(milliseconds: 100));
    verifyNever(() => useCases.getKandidat(
        search: 'bud', urutan: KandidatUrutan.namaAZ, termasukKosong: true));

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    verify(() => useCases.getKandidat(
        search: 'bud',
        urutan: KandidatUrutan.namaAZ,
        termasukKosong: true)).called(1);
    expect(find.text('Ahmad Ridwan'), findsNothing);
    expect(find.text('Budi Santoso'), findsOneWidget);
  });

  testWidgets('says so when nobody can be paid out', (tester) async {
    answer(rows: const []);
    await pump(tester);

    expect(find.text('Tidak ada nasabah yang dapat dicairkan'), findsOneWidget);
  });
}
