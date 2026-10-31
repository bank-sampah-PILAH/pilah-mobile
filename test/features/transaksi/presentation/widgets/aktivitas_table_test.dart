import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_table.dart';

ActivitasEntity _setoran(String name, String id) =>
    ActivitasEntity.fromTransaksi(TransaksiEntity(
      id: id,
      initials: 'AB',
      avatarColor: Colors.green.shade100,
      textColor: Colors.green,
      name: name,
      subtitle: '2 jenis sampah',
      amount: '+Rp 5.000',
      isWaSuccess: true,
      balance: '',
      items: const [],
      tanggal: DateTime(2026, 10, 5, 12),
    ));

TransaksiDetailEntity _detail(String item) => TransaksiDetailEntity(
      name: 'Nasabah',
      amountFormatted: 'Rp 5.000',
      balanceFormatted: 'Rp 10.000',
      waStatus: 'sent',
      items: [
        ItemSetoranEntity(
          jenis: item,
          berat: '2 kg',
          harga: 'Rp 1.000',
          subtotal: 'Rp 2.000',
        ),
      ],
    );

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
    Widget? toolbar,
    Widget? pagination,
    Future<TransaksiDetailEntity?> Function(String id)? loadSetoranDetail,
  }) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AktivitasTable(
          items: items,
          onTap: onTap ?? (_) {},
          loadSetoranDetail: loadSetoranDetail,
          footer: footer,
          toolbar: toolbar,
          pagination: pagination,
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

  testWidgets('each setoran row expands and collapses its own details',
      (tester) async {
    final items = [_setoran('Ani', 't1'), _setoran('Budi', 't2')];
    final tapped = <ActivitasEntity>[];
    final loaded = <String>[];
    await pumpTable(
      tester,
      items: items,
      onTap: tapped.add,
      loadSetoranDetail: (id) async {
        loaded.add(id);
        return _detail(id == 't1' ? 'Plastik' : 'Kardus');
      },
    );

    await tester.tap(find.text('Ani'));
    await tester.pumpAndSettle();
    expect(find.text('Plastik'), findsOneWidget);
    expect(find.text('Kardus'), findsNothing);
    expect(loaded, ['t1']);
    expect(tapped, isEmpty,
        reason: 'setoran taps expand instead of opening a sheet');

    await tester.tap(find.text('Budi'));
    await tester.pumpAndSettle();
    expect(find.text('Plastik'), findsOneWidget);
    expect(find.text('Kardus'), findsOneWidget);
    expect(loaded, ['t1', 't2']);

    await tester.tap(find.text('Ani'));
    await tester.pumpAndSettle();
    expect(find.text('Plastik'), findsNothing);
    expect(find.text('Kardus'), findsOneWidget);
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

  testWidgets('the card fills the screen and only its rows scroll',
      (tester) async {
    final items = [for (var i = 0; i < 30; i++) _pencairan('Nama $i')];
    await pumpTable(
      tester,
      items: items,
      toolbar: const Text('ringkasan'),
      pagination: const Text('halaman'),
    );

    final card = tester.getRect(find.byType(AktivitasTable));
    expect(card.height, greaterThan(850), reason: 'fills the body');
    // Summary above the column heads, pagination pinned at the card's bottom.
    expect(tester.getTopLeft(find.text('ringkasan')).dy,
        lessThan(tester.getTopLeft(find.text('WAKTU')).dy));
    expect(tester.getBottomLeft(find.text('halaman')).dy,
        lessThanOrEqualTo(card.bottom));
    expect(find.text('Nama 29'), findsNothing, reason: 'rows scroll inside');
    await tester.drag(find.byType(ListView), const Offset(0, -4000));
    await tester.pump();
    expect(find.text('Nama 29'), findsOneWidget);
    expect(find.text('halaman'), findsOneWidget, reason: 'footer stays put');
  });
}
