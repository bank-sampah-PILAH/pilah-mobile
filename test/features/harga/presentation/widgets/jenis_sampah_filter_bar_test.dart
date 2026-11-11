import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/theme/app_theme.dart';
import 'package:pilah_mobile/features/harga/domain/models/jenis_sampah_query.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/jenis_sampah_filter_bar.dart';

void main() {
  late JenisSampahQuery query;
  late StateSetter rebuild;
  final emitted = <JenisSampahQuery>[];

  Future<void> open(WidgetTester tester,
      {JenisSampahQuery start = const JenisSampahQuery()}) async {
    query = start;
    emitted.clear();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: StatefulBuilder(builder: (context, setState) {
          rebuild = setState;
          return JenisSampahFilterBar(
            query: query,
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
