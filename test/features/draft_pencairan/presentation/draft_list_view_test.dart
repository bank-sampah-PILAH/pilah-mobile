import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/model/draft_pencairan.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/repository/draft_pencairan_repository.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/blocs/draft_list_cubit.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/pages/draft_list_page.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/widgets/pencairan_ui.dart';

import '../../../support/pump_app.dart';

class _MockRepository extends Mock implements DraftPencairanRepository {}

DraftRingkasan _draft(String id, String nama, DraftStatus status) =>
    DraftRingkasan(
      id: id,
      nama: nama,
      status: status,
      dibuatOlehNama: 'Ibu Sari',
      createdAt: DateTime(2026, 10, 7, 9, 5),
      jumlahItem: 3,
      totalNominal: 150000,
      totalPotongan: 11500,
      totalDibayar: 138500,
    );

DraftPencairan _batal() => DraftPencairan(
      id: 'd-1',
      nama: 'Cair Oktober',
      status: DraftStatus.dibatalkan,
      potonganDefault: Potongan.nol,
      createdAt: DateTime(2026, 10, 7),
      updatedAt: DateTime(2026, 10, 7),
      items: const [],
      totalNominal: 0,
      totalPotongan: 0,
      totalDibayar: 0,
    );

void main() {
  late _MockRepository repository;

  setUp(() => repository = _MockRepository());

  Future<GoRouter> pump(
    WidgetTester tester,
    List<DraftRingkasan> drafts, {
    Size? size,
  }) async {
    when(() => repository.getDrafts()).thenAnswer((_) async => Right(drafts));
    return pumpRouted(
      tester,
      BlocProvider(
        create: (_) => DraftListCubit(repository)..load(),
        child: const DraftListView(),
      ),
      extraRoutes: const [
        DraftListPage.routePilih,
        DraftListPage.routeEditor,
      ],
      size: size,
    );
  }

  test('the page keeps the key it is given', () {
    // Built at run time on purpose: the router's const page never runs it.
    final key = UniqueKey();

    expect(DraftListPage(key: key).key, key);
  });

  testWidgets('has the pencairan header with a back button and pill filters',
      (tester) async {
    await pump(tester, const []);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('kembali')), findsOneWidget);
    expect(find.text('Pencairan'), findsOneWidget);
    expect(find.byType(PencairanChip), findsNWidgets(4));
  });

  testWidgets('shows each draft with its status, size, total and who made it',
      (tester) async {
    await pump(tester, [
      _draft('d-1', 'Cair Oktober', DraftStatus.draft),
      _draft('d-2', 'Cair September', DraftStatus.dikonfirmasi),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Cair Oktober'), findsOneWidget);
    expect(find.text('Cair September'), findsOneWidget);
    expect(find.text('Draft'), findsWidgets);
    expect(find.text('Dikonfirmasi'), findsWidgets);
    expect(find.textContaining('3 nasabah'), findsNWidgets(2));
    expect(find.textContaining('Rp 138.500'), findsNWidgets(2));
    expect(find.textContaining('Ibu Sari'), findsNWidgets(2));
    expect(find.textContaining('7 Okt 2026'), findsNWidgets(2));
  });

  testWidgets('draft cards are white with a soft shadow', (tester) async {
    await pump(tester, [_draft('d-1', 'Cair Oktober', DraftStatus.draft)]);
    await tester.pumpAndSettle();

    final decoration = tester
        .widget<Container>(find
            .descendant(
                of: find.byKey(const Key('draft-d-1')),
                matching: find.byType(Container))
            .first)
        .decoration! as BoxDecoration;
    expect(decoration.color, Colors.white);
    expect(decoration.border, isNull);
    expect(decoration.boxShadow, isNotEmpty);
  });

  testWidgets('a status chip narrows the list', (tester) async {
    await pump(tester, [
      _draft('d-1', 'Cair Oktober', DraftStatus.draft),
      _draft('d-2', 'Cair September', DraftStatus.dikonfirmasi),
    ]);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('filter-dikonfirmasi')));
    await tester.pumpAndSettle();

    expect(find.text('Cair Oktober'), findsNothing);
    expect(find.text('Cair September'), findsOneWidget);

    await tester.tap(find.byKey(const Key('filter-semua')));
    await tester.pumpAndSettle();

    expect(find.text('Cair Oktober'), findsOneWidget);
  });

  testWidgets('says so when there are no drafts yet', (tester) async {
    await pump(tester, const []);
    await tester.pumpAndSettle();

    expect(find.text('Belum ada draft pencairan'), findsOneWidget);
  });

  testWidgets('a failed load can be retried', (tester) async {
    when(() => repository.getDrafts())
        .thenAnswer((_) async => Left(ConnectionTimeOutException()));
    await pumpRouted(
      tester,
      BlocProvider(
        create: (_) => DraftListCubit(repository)..load(),
        child: const DraftListView(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Coba lagi'), findsOneWidget);

    when(() => repository.getDrafts()).thenAnswer(
        (_) async => Right([_draft('d-1', 'Cair Oktober', DraftStatus.draft)]));
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Cair Oktober'), findsOneWidget);
  });

  testWidgets('the add button starts picking nasabah', (tester) async {
    await pump(tester, const []);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Buat Pencairan'));
    await tester.pumpAndSettle();

    expect(find.text('route:${DraftListPage.routePilih}'), findsOneWidget);
  });

  testWidgets(
      'picked nasabah open a new editor, and the list reloads once it is left',
      (tester) async {
    final router = await pump(tester, const []);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buat Pencairan'));
    await tester.pumpAndSettle();

    router.pop(const [
      Kandidat(id: 'n-1', kode: 'NAS-0001', nama: 'Ahmad Ridwan', saldo: 1000),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('route:${DraftListPage.routeEditor}'), findsOneWidget);
    clearInteractions(repository);

    router.pop();
    await tester.pumpAndSettle();

    verify(() => repository.getDrafts()).called(1);
  });

  testWidgets('leaving the picker without picking does not open an editor',
      (tester) async {
    final router = await pump(tester, const []);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buat Pencairan'));
    await tester.pumpAndSettle();

    router.pop();
    await tester.pumpAndSettle();

    expect(find.text('route:${DraftListPage.routeEditor}'), findsNothing);
  });

  testWidgets('opening a draft goes to the editor', (tester) async {
    await pump(tester, [_draft('d-1', 'Cair Oktober', DraftStatus.draft)]);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cair Oktober'));
    await tester.pumpAndSettle();

    expect(find.text('route:${DraftListPage.routeEditor}'), findsOneWidget);
  });

  testWidgets('the list reloads when an opened draft is left', (tester) async {
    final router =
        await pump(tester, [_draft('d-1', 'Cair Oktober', DraftStatus.draft)]);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cair Oktober'));
    await tester.pumpAndSettle();
    clearInteractions(repository);

    router.pop();
    await tester.pumpAndSettle();

    verify(() => repository.getDrafts()).called(1);
  });

  testWidgets('only a draft in progress can be cancelled from its card',
      (tester) async {
    await pump(tester, [
      _draft('d-1', 'Cair Oktober', DraftStatus.draft),
      _draft('d-2', 'Cair September', DraftStatus.dikonfirmasi),
      _draft('d-3', 'Cair Agustus', DraftStatus.dibatalkan),
    ]);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('batalkan-d-1')), findsOneWidget);
    expect(find.byKey(const Key('batalkan-d-2')), findsNothing);
    expect(find.byKey(const Key('batalkan-d-3')), findsNothing);
  });

  testWidgets('a draft in a status the app does not know cannot be cancelled',
      (tester) async {
    await pump(
        tester, [_draft('d-1', 'Cair Oktober', DraftStatus.tidakDikenal)]);
    await tester.pumpAndSettle();

    expect(find.text('Tidak dikenal'), findsOneWidget);
    expect(find.byKey(const Key('batalkan-d-1')), findsNothing);
  });

  testWidgets('on a desktop window the list keeps to a centred column',
      (tester) async {
    await pump(tester, [_draft('d-1', 'Cair Oktober', DraftStatus.draft)],
        size: const Size(1440, 900));
    await tester.pumpAndSettle();

    final kartu = find
        .ancestor(
            of: find.text('Cair Oktober'), matching: find.byType(PencairanCard))
        .first;
    expect(tester.getSize(kartu).width,
        lessThanOrEqualTo(LayoutBreakpoint.contentMaxWidth));
    expect(tester.getCenter(kartu).dx, closeTo(720, 1),
        reason: 'centred in the window');
    expect(tester.getSize(find.byKey(const Key('cari-draft'))).width,
        lessThanOrEqualTo(LayoutBreakpoint.contentMaxWidth));
  });

  testWidgets('the trash icon asks first, then cancels and reloads',
      (tester) async {
    await pump(tester, [_draft('d-1', 'Cair Oktober', DraftStatus.draft)],
        size: const Size(390, 844));
    await tester.pumpAndSettle();
    when(() => repository.cancelDraft('d-1'))
        .thenAnswer((_) async => Right(_batal()));
    when(() => repository.getDrafts()).thenAnswer((_) async =>
        Right([_draft('d-1', 'Cair Oktober', DraftStatus.dibatalkan)]));

    await tester.tap(find.byKey(const Key('batalkan-d-1')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Batalkan draft?'), findsOneWidget);
    expect(find.textContaining('Cair Oktober'), findsWidgets);
    verifyNever(() => repository.cancelDraft(any()));

    await tester.tap(find.text('Ya, batalkan'));
    await tester.pumpAndSettle();

    verify(() => repository.cancelDraft('d-1')).called(1);
    expect(find.byKey(const Key('batalkan-d-1')), findsNothing);
  });

  testWidgets('a cancel that fails says so and keeps the draft',
      (tester) async {
    await pump(tester, [_draft('d-1', 'Cair Oktober', DraftStatus.draft)]);
    await tester.pumpAndSettle();
    when(() => repository.cancelDraft('d-1'))
        .thenAnswer((_) async => Left(ConnectionTimeOutException()));

    await tester.tap(find.byKey(const Key('batalkan-d-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya, batalkan'));
    await pumpToast(tester);

    expect(find.text('Gagal'), findsOneWidget);
    expect(find.byKey(const Key('batalkan-d-1')), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('backing out of the question cancels nothing', (tester) async {
    await pump(tester, [_draft('d-1', 'Cair Oktober', DraftStatus.draft)]);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('batalkan-d-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();

    verifyNever(() => repository.cancelDraft(any()));
    expect(find.byKey(const Key('batalkan-d-1')), findsOneWidget);
  });

  testWidgets('the header has no menu to log a pencairan for one nasabah',
      (tester) async {
    await pump(tester, const []);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('menu-lainnya')), findsNothing);
    expect(find.text('Catat pencairan satu nasabah'), findsNothing);
  });

  testWidgets(
      'a card shows the total paid, with saldo and potongan folded away',
      (tester) async {
    await pump(tester, [_draft('d-1', 'Cair Oktober', DraftStatus.draft)]);
    await tester.pumpAndSettle();

    expect(find.text('Total dibayar'), findsOneWidget);
    expect(find.text('Rp 138.500'), findsOneWidget);
    expect(find.byKey(const Key('total-saldo-d-1')), findsNothing);
    expect(find.byKey(const Key('total-potongan-d-1')), findsNothing);
  });

  testWidgets('the chevron unfolds total saldo and a yellow potongan',
      (tester) async {
    await pump(tester, [_draft('d-1', 'Cair Oktober', DraftStatus.draft)]);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('ekspan-d-1')));
    await tester.pumpAndSettle();

    expect(find.text('Total saldo'), findsOneWidget);
    expect(find.text('Rp 150.000'), findsOneWidget);
    final potongan = tester.widget<Text>(find.descendant(
        of: find.byKey(const Key('total-potongan-d-1')),
        matching: find.textContaining('11.500')));
    expect(potongan.data, '\u2212 Rp 11.500');
    expect(potongan.style?.color, AppColors.statOrange);

    await tester.tap(find.byKey(const Key('ekspan-d-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('total-saldo-d-1')), findsNothing);
  });

  testWidgets('unfolding a card does not open the draft', (tester) async {
    await pump(tester, [_draft('d-1', 'Cair Oktober', DraftStatus.draft)]);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('ekspan-d-1')));
    await tester.pumpAndSettle();

    expect(find.text('route:${DraftListPage.routeEditor}'), findsNothing);
  });

  testWidgets('the potongan row stays, plainly Rp 0, when nothing is deducted',
      (tester) async {
    await pump(tester, [
      DraftRingkasan(
        id: 'd-9',
        nama: 'Tanpa potongan',
        status: DraftStatus.draft,
        jumlahItem: 1,
        totalNominal: 50000,
        totalPotongan: 0,
        totalDibayar: 50000,
      ),
    ]);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('ekspan-d-9')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('total-saldo-d-9')), findsOneWidget);
    final potongan = tester.widget<Text>(find.descendant(
        of: find.byKey(const Key('total-potongan-d-9')),
        matching: find.text('Rp 0')));
    expect(potongan.style?.color, isNot(AppColors.statOrange));
  });

  testWidgets('the footer has the pengurus avatar and a clock by the time',
      (tester) async {
    await pump(tester, [_draft('d-1', 'Cair Oktober', DraftStatus.draft)]);
    await tester.pumpAndSettle();

    final footer = find.byKey(const Key('footer-d-1'));
    expect(find.descendant(of: footer, matching: find.byType(PencairanAvatar)),
        findsOneWidget);
    expect(find.descendant(of: footer, matching: find.text('Ibu Sari')),
        findsOneWidget);
    expect(find.descendant(of: footer, matching: find.byIcon(Icons.schedule)),
        findsOneWidget);
    expect(
        find.descendant(
            of: footer, matching: find.textContaining('7 Okt 2026, 09:05')),
        findsOneWidget);
  });

  group('finding a draft', () {
    DraftRingkasan row(String id, String nama,
            {DraftStatus status = DraftStatus.draft,
            DateTime? dibuat,
            int dibayar = 100000}) =>
        DraftRingkasan(
          id: id,
          nama: nama,
          status: status,
          dibuatOlehNama: 'Ibu Sari',
          createdAt: dibuat,
          jumlahItem: 1,
          totalNominal: dibayar,
          totalPotongan: 0,
          totalDibayar: dibayar,
        );

    final now = DateTime.now();
    final rows = [
      row('a', 'Alfa', dibuat: now, dibayar: 100000),
      row('b', 'Bravo',
          dibuat: now.subtract(const Duration(days: 40)),
          status: DraftStatus.dikonfirmasi,
          dibayar: 900000),
    ];

    testWidgets('typing in the search field narrows the list', (tester) async {
      await pump(tester, rows);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('cari-draft')), 'bra');
      await tester.pumpAndSettle();

      expect(find.text('Bravo'), findsOneWidget);
      expect(find.text('Alfa'), findsNothing);
    });

    testWidgets('a search with no match says so and can be cleared',
        (tester) async {
      await pump(tester, rows);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('cari-draft')), 'zzz');
      await tester.pumpAndSettle();
      expect(find.textContaining("Tidak ada pencairan untuk 'zzz'"),
          findsOneWidget);

      await tester.tap(find.byKey(const Key('hapus-pencarian')));
      await tester.pumpAndSettle();
      expect(find.text('Alfa'), findsOneWidget);
      expect(find.text('Bravo'), findsOneWidget);
    });

    testWidgets('each status chip carries how many drafts it holds',
        (tester) async {
      await pump(tester, rows);
      await tester.pumpAndSettle();

      Finder count(String chip, String n) =>
          find.descendant(of: find.byKey(Key(chip)), matching: find.text(n));
      expect(count('filter-semua', '2'), findsOneWidget);
      expect(count('filter-draft', '1'), findsOneWidget);
      expect(count('filter-dikonfirmasi', '1'), findsOneWidget);
      expect(count('filter-dibatalkan', '0'), findsOneWidget);
    });

    testWidgets('no counts are shown until the drafts have loaded',
        (tester) async {
      final pending =
          Completer<Either<NetworkException, List<DraftRingkasan>>>();
      when(() => repository.getDrafts()).thenAnswer((_) => pending.future);
      await pumpRouted(
        tester,
        BlocProvider(
          create: (_) => DraftListCubit(repository)..load(),
          child: const DraftListView(),
        ),
      );
      await tester.pump();

      expect(
          tester
              .widget<PencairanChip>(find.byKey(const Key('filter-semua')))
              .count,
          isNull);

      pending.complete(Right(rows));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<PencairanChip>(find.byKey(const Key('filter-semua')))
              .count,
          2);
    });

    testWidgets(
        'the sort button sits beside the search field, as in the editor',
        (tester) async {
      await pump(tester, rows);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('urutkan-draft')), findsOneWidget);
      expect(find.byIcon(Icons.swap_vert), findsOneWidget);
      expect(find.byKey(const Key('urutan')), findsNothing,
          reason: 'no sort chip any more');
      final cari = tester.getRect(find.byKey(const Key('cari-draft')));
      final urut = tester.getRect(find.byKey(const Key('urutkan-draft')));
      expect(urut.left, greaterThanOrEqualTo(cari.right));
      expect((urut.center.dy - cari.center.dy).abs(), lessThan(4));
    });

    testWidgets('its menu offers date, total paid and name', (tester) async {
      await pump(tester, rows);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('urutkan-draft')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('urut-draft-tanggal')), findsOneWidget);
      expect(find.byKey(const Key('urut-draft-dibayar')), findsOneWidget);
      expect(find.byKey(const Key('urut-draft-nama')), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget,
          reason: 'the date, newest first, is the current order');
    });

    testWidgets('picking total paid re-sorts, and the menu stays open',
        (tester) async {
      await pump(tester, rows);
      await tester.pumpAndSettle();
      expect(
          tester.getTopLeft(find.text('Alfa')).dy <
              tester.getTopLeft(find.text('Bravo')).dy,
          isTrue);

      await tester.tap(find.byKey(const Key('urutkan-draft')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('urut-draft-dibayar')));
      await tester.pumpAndSettle();

      expect(
          tester.getTopLeft(find.text('Bravo')).dy <
              tester.getTopLeft(find.text('Alfa')).dy,
          isTrue);
      expect(find.byKey(const Key('urut-draft-nama')), findsOneWidget,
          reason: 'still open for another try');
    });

    testWidgets('drafts sit under date headings only in the time orders',
        (tester) async {
      await pump(tester, rows);
      await tester.pumpAndSettle();
      expect(find.text('HARI INI'), findsOneWidget);

      await tester.tap(find.byKey(const Key('urutkan-draft')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('urut-draft-dibayar')));
      await tester.pumpAndSettle();

      expect(find.text('HARI INI'), findsNothing);
    });
  });
}
