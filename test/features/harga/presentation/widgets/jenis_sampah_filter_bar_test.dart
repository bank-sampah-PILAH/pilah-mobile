import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/theme/app_theme.dart';
import 'package:pilah_mobile/design/widgets/app_chip.dart';
import 'package:pilah_mobile/features/harga/domain/models/jenis_sampah_query.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/jenis_sampah_filter_bar.dart';

void main() {
  late JenisSampahQuery query;
  late List<String> kategori;
  late StateSetter rebuild;
  final emitted = <JenisSampahQuery>[];

  Future<void> open(WidgetTester tester,
      {JenisSampahQuery start = const JenisSampahQuery(),
      List<String> cats = const ['kertas', 'plastik', 'dll']}) async {
    query = start;
    kategori = cats;
    emitted.clear();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: StatefulBuilder(builder: (context, setState) {
          rebuild = setState;
          return JenisSampahFilterBar(
            query: query,
            kategori: kategori,
            onChanged: (q) {
              emitted.add(q);
              setState(() => query = q);
            },
          );
        }),
      ),
    ));
  }

  testWidgets('typing searches', (tester) async {
    await open(tester);
    await tester.enterText(find.byKey(const Key('cari-jenis-sampah')), 'botol');
    expect(emitted.single.search, 'botol');
  });

  testWidgets('a reset from outside empties the search field', (tester) async {
    await open(tester, start: const JenisSampahQuery(search: 'botol'));
    expect(find.text('botol'), findsOneWidget);

    rebuild(() => query = const JenisSampahQuery());
    await tester.pump();

    expect(find.text('botol'), findsNothing);
  });

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('filter-kategori')));
    await tester.pumpAndSettle();
  }

  // CheckboxMenuButton hands its key on to the MenuItemButton inside it, so a
  // key finds two widgets; the outer one is first.
  Finder box(String key) => find.byKey(Key(key)).first;

  bool checked(WidgetTester tester, String key) =>
      tester.widget<CheckboxMenuButton>(box(key)).value!;

  testWidgets('one chip says Semua kategori by default, with a down arrow',
      (tester) async {
    await open(tester);

    expect(find.text('Semua kategori'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    expect(find.text('Plastik'), findsNothing, reason: 'menu is closed');
  });

  testWidgets('the menu has a checkbox per category, all ticked at first',
      (tester) async {
    await open(tester);
    await openMenu(tester);

    for (final t in ['Kertas', 'Plastik', 'Lainnya']) {
      expect(find.text(t), findsOneWidget);
    }
    for (final k in ['semua', 'kertas', 'plastik', 'dll']) {
      expect(checked(tester, 'kategori-$k'), isTrue, reason: k);
    }
  });

  testWidgets('unticking narrows the choice and the chip says how many',
      (tester) async {
    await open(tester);
    await openMenu(tester);

    await tester.tap(box('kategori-plastik'));
    await tester.pumpAndSettle();
    expect(emitted.last.kategori, {'kertas', 'dll'});
    expect(find.text('2 kategori'), findsOneWidget);
    expect(checked(tester, 'kategori-plastik'), isFalse);
    expect(checked(tester, 'kategori-semua'), isFalse);

    await tester.tap(box('kategori-kertas'));
    await tester.pumpAndSettle();
    expect(emitted.last.kategori, {'dll'});
    expect(find.text('Lainnya'), findsWidgets);
    expect(find.text('2 kategori'), findsNothing);
  });

  testWidgets('removing the last tick leaves no category at all',
      (tester) async {
    await open(tester,
        start: const JenisSampahQuery(kategori: {'plastik'}),
        cats: const ['kertas', 'plastik']);
    await openMenu(tester);

    await tester.tap(box('kategori-plastik'));
    await tester.pumpAndSettle();

    expect(query.tidakAdaKategori, isTrue);
    expect(find.text('Tidak ada kategori'), findsOneWidget);
    expect(checked(tester, 'kategori-plastik'), isFalse);
    expect(checked(tester, 'kategori-semua'), isFalse);
    expect(
        tester
            .widget<AppChip>(find.byKey(const Key('filter-kategori')))
            .selected,
        isTrue,
        reason: 'none ticked');
  });

  testWidgets(
      'Semua kategori unticks everything when all are ticked, and '
      'ticks everything otherwise', (tester) async {
    await open(tester);
    await openMenu(tester);

    await tester.tap(box('kategori-semua'));
    await tester.pumpAndSettle();
    expect(query.tidakAdaKategori, isTrue);
    for (final k in ['kertas', 'plastik', 'dll']) {
      expect(checked(tester, 'kategori-$k'), isFalse, reason: k);
    }

    await tester.tap(box('kategori-plastik'));
    await tester.pumpAndSettle();
    expect(query.kategori, {'plastik'});

    await tester.tap(box('kategori-semua'));
    await tester.pumpAndSettle();
    expect(query.kategori, isNull);
    expect(checked(tester, 'kategori-semua'), isTrue);
  });

  testWidgets('ticking everything again, or Semua kategori, clears the filter',
      (tester) async {
    await open(tester, start: const JenisSampahQuery(kategori: {'plastik'}));
    await openMenu(tester);

    await tester.tap(box('kategori-kertas'));
    await tester.pumpAndSettle();
    expect(query.kategori, {'plastik', 'kertas'});

    await tester.tap(box('kategori-dll'));
    await tester.pumpAndSettle();
    expect(query.kategori, isNull, reason: 'all three ticked is no filter');

    await tester.tap(box('kategori-kertas'));
    await tester.pumpAndSettle();
    expect(query.kategori, {'plastik', 'dll'});
    await tester.tap(box('kategori-semua'));
    await tester.pumpAndSettle();
    expect(query.kategori, isNull);
    expect(find.text('Semua kategori'), findsWidgets);
  });

  testWidgets('the chip is green whatever is ticked, since it always applies',
      (tester) async {
    await open(tester);
    AppChip chip() =>
        tester.widget<AppChip>(find.byKey(const Key('filter-kategori')));
    expect(chip().selected, isTrue, reason: 'all categories');

    await openMenu(tester);
    await tester.tap(box('kategori-kertas'));
    await tester.pumpAndSettle();
    expect(chip().selected, isTrue, reason: 'some categories');

    await tester.tap(box('kategori-semua'));
    await tester.pumpAndSettle();
    await tester.tap(box('kategori-semua'));
    await tester.pumpAndSettle();
    expect(chip().selected, isTrue, reason: 'back to all');
  });

  testWidgets('no filter when there is nothing to choose between',
      (tester) async {
    await open(tester, cats: const ['plastik']);
    expect(find.byKey(const Key('filter-kategori')), findsNothing);
    await open(tester, cats: const []);
    expect(find.byKey(const Key('filter-kategori')), findsNothing);
  });

  testWidgets('sort: another field starts ascending, the same one flips',
      (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('urutkan-jenis-sampah')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('urut-jenis-sampah-harga')));
    await tester.pump();
    expect(emitted.last.sortField, JenisSampahSortField.harga);
    expect(emitted.last.ascending, isTrue);

    await tester.tap(find.byKey(const Key('urut-jenis-sampah-harga')));
    await tester.pump();
    expect(emitted.last.sortField, JenisSampahSortField.harga);
    expect(emitted.last.ascending, isFalse);

    await tester.tap(find.byKey(const Key('urut-jenis-sampah-nama')));
    await tester.pump();
    expect(emitted.last.sortField, JenisSampahSortField.nama);
    expect(emitted.last.ascending, isTrue);
  });
}
