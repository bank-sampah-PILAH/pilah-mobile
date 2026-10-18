import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_terjadwal.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/harga_detail_sheet.dart';

HargaEntity _item({bool active = true, HargaTerjadwal? terjadwal}) =>
    HargaEntity(
      id: '1',
      kodeSampah: 'PET',
      name: 'Plastik PET',
      price: 3500,
      priceFormatted: 'Rp 3.500',
      category: 'anorganik',
      subtitle: 'Botol plastik bening',
      badgeText: 'Anorganik',
      icon: Icons.local_drink,
      iconColor: Colors.blue,
      isActive: active,
      berlakuMulai: DateTime.utc(2026, 10, 1),
      hargaTerjadwal: terjadwal,
    );

Future<void> _pump(
  WidgetTester tester,
  HargaEntity item, {
  VoidCallback? onEdit,
  VoidCallback? onRiwayat,
}) =>
    tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: HargaDetailSheet(
            item: item,
            onEdit: onEdit ?? () {},
            onRiwayat: onRiwayat ?? () {},
          ),
        ),
      ),
    ));

void main() {
  testWidgets('shows what the jenis sampah is and what it pays',
      (tester) async {
    await _pump(tester, _item());

    expect(find.text('Plastik PET'), findsOneWidget);
    expect(find.text('Botol plastik bening'), findsOneWidget);
    expect(find.text('Anorganik'), findsOneWidget);
    expect(find.text('Aktif'), findsOneWidget);
    expect(find.text('Rp 3.500 / kg'), findsOneWidget);
    expect(find.text('Berlaku sejak'), findsOneWidget);
  });

  testWidgets('a deactivated jenis says so', (tester) async {
    await _pump(tester, _item(active: false));

    expect(find.text('Nonaktif'), findsOneWidget);
  });

  testWidgets('a scheduled price shows with the day it starts',
      (tester) async {
    await _pump(
      tester,
      _item(
        terjadwal: HargaTerjadwal(
            harga: 4000, berlakuMulai: DateTime.utc(2026, 11, 1, 5)),
      ),
    );

    expect(find.text('Harga terjadwal'), findsOneWidget);
    expect(find.textContaining('Rp 4.000'), findsOneWidget);
  });

  testWidgets('without a scheduled price there is no such row',
      (tester) async {
    await _pump(tester, _item());

    expect(find.text('Harga terjadwal'), findsNothing);
  });

  testWidgets('the two actions are Edit and Riwayat harga', (tester) async {
    var edited = 0;
    var history = 0;
    await _pump(tester, _item(),
        onEdit: () => edited++, onRiwayat: () => history++);

    await tester.tap(find.text('Edit'));
    await tester.tap(find.text('Riwayat harga'));

    expect(edited, 1);
    expect(history, 1);
  });
}
