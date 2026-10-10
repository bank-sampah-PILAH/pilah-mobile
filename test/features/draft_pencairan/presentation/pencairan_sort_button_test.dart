import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/widgets/pencairan_sort_button.dart';

enum _Field { tanggal, dibayar, nama }

void main() {
  const labels = {
    _Field.tanggal: 'Tanggal',
    _Field.dibayar: 'Total dibayar',
    _Field.nama: 'Nama',
  };

  Future<void> pumpAt(
    WidgetTester tester, {
    required _Field current,
    bool ascending = false,
  }) async {
    tester.view.physicalSize = const Size(486, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      key: UniqueKey(),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          // The button hugs the right edge, as beside a search field.
          child: Row(
            children: [
              const Spacer(),
              PencairanSortButton<_Field>(
                buttonKey: const Key('urutkan'),
                itemKeyPrefix: 'urut-',
                fields: _Field.values,
                labelOf: (f) => labels[f]!,
                current: current,
                ascending: ascending,
                onSort: (_) {},
              ),
            ],
          ),
        ),
      ),
    ));
    await tester.tap(find.byKey(const Key('urutkan')));
    await tester.pumpAndSettle();
  }

  Rect item(WidgetTester tester, _Field f) =>
      tester.getRect(find.byKey(Key('urut-${f.name}')));

  testWidgets('the menu keeps clear of the right edge of the screen',
      (tester) async {
    await pumpAt(tester, current: _Field.tanggal);

    for (final f in _Field.values) {
      expect(item(tester, f).right, lessThanOrEqualTo(486 - 16));
    }
  });

  testWidgets('the menu is wide enough to read at a glance', (tester) async {
    await pumpAt(tester, current: _Field.tanggal);

    expect(item(tester, _Field.dibayar).width, greaterThanOrEqualTo(200));
  });

  testWidgets('every row is as wide as the others', (tester) async {
    await pumpAt(tester, current: _Field.dibayar);

    final widths = {for (final f in _Field.values) item(tester, f).width};
    expect(widths, hasLength(1));
  });

  testWidgets('the width does not depend on which field is current',
      (tester) async {
    await pumpAt(tester, current: _Field.tanggal);
    final first = item(tester, _Field.nama);

    await pumpAt(tester, current: _Field.dibayar, ascending: true);
    final second = item(tester, _Field.nama);

    await pumpAt(tester, current: _Field.nama);
    final third = item(tester, _Field.nama);

    expect(second.width, first.width);
    expect(third.width, first.width);
    expect(second.left, first.left);
    expect(third.left, first.left);
  });

  testWidgets('the direction arrow is anchored to the right of its row',
      (tester) async {
    await pumpAt(tester, current: _Field.dibayar);

    final row = item(tester, _Field.dibayar);
    final arrow = tester.getRect(find.descendant(
        of: find.byKey(const Key('urut-dibayar')),
        matching: find.byIcon(Icons.arrow_downward)));
    expect(row.right - arrow.right, lessThanOrEqualTo(20));
    expect(arrow.left, greaterThan(row.center.dx));
  });

  testWidgets('only the current field shows an arrow, up when ascending',
      (tester) async {
    await pumpAt(tester, current: _Field.nama, ascending: true);

    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    expect(find.byIcon(Icons.arrow_downward), findsNothing);
    expect(
        find.descendant(
            of: find.byKey(const Key('urut-nama')),
            matching: find.byIcon(Icons.arrow_upward)),
        findsOneWidget);
  });

  testWidgets('labels line up on the left whatever the current field',
      (tester) async {
    await pumpAt(tester, current: _Field.tanggal);
    final a = tester.getTopLeft(find.text('Nama')).dx;
    await pumpAt(tester, current: _Field.nama);
    final b = tester.getTopLeft(find.text('Nama')).dx;

    expect(b, a);
  });
}
