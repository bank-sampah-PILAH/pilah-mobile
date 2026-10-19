import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_entity.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_table.dart';

ActivitasEntity _pencairan(String name) =>
    ActivitasEntity.fromPencairan(Pencairan(
      id: 'p-1',
      nasabahId: 'n-1',
      nasabahNama: name,
      nominal: 15000,
      metode: MetodePencairan.tunai,
      tanggal: DateTime(2026, 9, 22, 10),
      keterangan: '',
      status: 'tercatat',
      saldoSebelum: 20000,
      saldoSesudah: 5000,
      dicatatOlehNama: 'Ibu Sari',
    ));

void main() {
  Future<void> pumpTable(
    WidgetTester tester, {
    required List<ActivitasEntity> items,
    ValueChanged<ActivitasEntity>? onTap,
    List<Widget> footer = const [],
  }) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: AktivitasTable(
            items: items,
            onTap: onTap ?? (_) {},
            footer: footer,
          ),
        ),
      ),
    ));
  }

  testWidgets('shows column headings and one row per activity', (tester) async {
    await pumpTable(tester, items: [_pencairan('Ani'), _pencairan('Budi')]);

    for (final heading in ['WAKTU', 'NASABAH', 'TIPE', 'RINCIAN', 'NOMINAL']) {
      expect(find.text(heading), findsOneWidget);
    }
    expect(find.text('Ani'), findsOneWidget);
    expect(find.text('Budi'), findsOneWidget);
    expect(find.text('Pencairan'), findsNWidgets(2));
    expect(find.byKey(AktivitasTable.rowKey(0)), findsOneWidget);
    expect(find.byKey(AktivitasTable.rowKey(1)), findsOneWidget);
    expect(find.byKey(AktivitasTable.rowKey(2)), findsNothing);
  });

  testWidgets('a pencairan amount is red', (tester) async {
    await pumpTable(tester, items: [_pencairan('Ani')]);

    final amount = tester.widget<Text>(find.text('-Rp 15.000'));
    expect(amount.style!.color, AppColors.danger);
  });

  testWidgets('tapping a row reports that activity', (tester) async {
    final items = [_pencairan('Ani'), _pencairan('Budi')];
    ActivitasEntity? tapped;
    await pumpTable(tester, items: items, onTap: (item) => tapped = item);

    await tester.tap(find.text('Budi'));

    expect(tapped, same(items[1]));
  });

  testWidgets('renders the footer below the last row', (tester) async {
    await pumpTable(
      tester,
      items: [_pencairan('Ani')],
      footer: const [Text('Muat Lagi')],
    );

    expect(tester.getTopLeft(find.text('Muat Lagi')).dy,
        greaterThan(tester.getBottomLeft(find.text('Ani')).dy));
  });

  testWidgets('hovering a row tints it like the nasabah table', (tester) async {
    await pumpTable(tester, items: [_pencairan('Ani'), _pencairan('Budi')]);
    Color? tint(int i) => tester
        .widget<Container>(find
            .descendant(
                of: find.byKey(AktivitasTable.rowKey(i)),
                matching: find.byType(Container))
            .first)
        .color;
    expect(tint(0), isNull);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byKey(AktivitasTable.rowKey(0))));
    await tester.pump();

    expect(tint(0), AppColors.greenLight.withValues(alpha: 0.45));
    expect(tint(1), isNull);

    await mouse.moveTo(const Offset(1, 1));
    await tester.pump();

    expect(tint(0), isNull);
  });
}
