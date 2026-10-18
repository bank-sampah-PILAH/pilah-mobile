import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_terjadwal.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/harga_table.dart';

HargaEntity _item(String id, String name,
        {bool active = true, HargaTerjadwal? terjadwal}) =>
    HargaEntity(
      id: id,
      kodeSampah: 'K$id',
      name: name,
      price: 3500,
      priceFormatted: 'Rp 3.500',
      category: 'anorganik',
      subtitle: 'desk $name',
      badgeText: 'Anorganik',
      icon: Icons.recycling,
      iconColor: Colors.green,
      isActive: active,
      hargaTerjadwal: terjadwal,
    );

Future<void> _pump(
  WidgetTester tester,
  List<HargaEntity> items, {
  ValueChanged<HargaEntity>? onTap,
  String? selectedId,
}) async {
  tester.view.physicalSize = const Size(1000, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: HargaTable(
        items: items,
        selectedId: selectedId,
        onTap: onTap ?? (_) {},
      ),
    ),
  ));
}

void main() {
  testWidgets('has a header and one row per jenis sampah', (tester) async {
    await _pump(tester, [_item('1', 'Botol PET'), _item('2', 'Kardus')]);

    for (final label in [
      'JENIS SAMPAH',
      'KATEGORI',
      'HARGA BELI / KG',
      'STATUS'
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    for (final name in ['Botol PET', 'Kardus']) {
      expect(find.text(name), findsOneWidget);
      expect(find.text('desk $name'), findsOneWidget);
    }
    expect(find.text('Anorganik'), findsNWidgets(2));
    expect(find.text('Rp 3.500'), findsNWidgets(2));
    expect(find.text('Aktif'), findsNWidgets(2));
  });

  testWidgets('a deactivated row says Nonaktif', (tester) async {
    await _pump(tester, [_item('1', 'Kaleng', active: false)]);

    expect(find.text('Nonaktif'), findsOneWidget);
  });

  testWidgets('a scheduled price shows under the price of its row',
      (tester) async {
    await _pump(tester, [
      _item('1', 'Botol PET',
          terjadwal: HargaTerjadwal(
              harga: 4000, berlakuMulai: DateTime.utc(2026, 11, 1, 5))),
    ]);

    final price = tester.getTopLeft(find.text('Rp 3.500'));
    final scheduled = tester.getTopLeft(find.textContaining('Rp 4.000'));
    expect(scheduled.dy, greaterThan(price.dy));
    expect(scheduled.dx, price.dx);
  });

  testWidgets('tapping a row reports that jenis', (tester) async {
    HargaEntity? tapped;
    await _pump(tester, [_item('1', 'Botol PET'), _item('2', 'Kardus')],
        onTap: (item) => tapped = item);

    await tester.tap(find.text('Kardus'));

    expect(tapped?.id, '2');
  });

  testWidgets('the selected row is tinted', (tester) async {
    await _pump(tester, [_item('1', 'Botol PET'), _item('2', 'Kardus')],
        selectedId: '2');

    Color? tint(String id) =>
        tester.widget<Container>(find.byKey(HargaTable.rowKey(id))).color;
    expect(tint('2'), AppColors.greenLight);
    expect(tint('1'), isNull);
  });

  testWidgets('a long name stays on one line', (tester) async {
    await _pump(tester, [
      _item('1', 'Botol plastik bening berukuran sangat besar sekali ' * 3),
    ]);

    expect(tester.takeException(), isNull);
  });
}
