import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/harga/data/models/harga_model.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/item_setoran_card.dart';

import '../../../../support/harga_support.dart';
import '../../../../support/stub_api.dart';

class _PickerHargaNotifier extends TestHargaNotifier {
  _PickerHargaNotifier(this.extraOptions)
      : super(buildHargaNotifier(StubApi()));

  final int extraOptions;

  @override
  List<HargaEntity> get activeJenisSampah => [
        for (var i = 0; i < extraOptions; i++)
          HargaModel.fromJson({
            'id': 'item-$i',
            'nama_sampah': 'Kertas $i',
            'kategori': 'kertas',
          }),
        HargaModel.fromJson({
          'id': 'pet',
          'nama_sampah': 'Botol PET',
          'kategori': 'plastik',
          'harga_per_kg': 2000,
        }),
        HargaModel.fromJson({
          'id': 'kardus',
          'nama_sampah': 'Kardus',
          'kategori': 'kertas',
          'harga_per_kg': 1000,
        }),
      ];
}

Future<List<Map<String, dynamic>>> openPicker(
  WidgetTester tester, {
  int extraOptions = 0,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 800);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final changes = <Map<String, dynamic>>[];
  await tester.pumpWidget(
    withHargaProvider(
      _PickerHargaNotifier(extraOptions),
      MaterialApp(
        home: Scaffold(
          body: ItemSetoranCard(
            index: 0,
            itemData: const {'berat': 2.5},
            onChanged: changes.add,
            onDelete: () {},
          ),
        ),
      ),
    ),
  );
  await tester.tapAt(tester.getCenter(find.text('Pilih Jenis')));
  await tester.pumpAndSettle();
  return changes;
}

void main() {
  testWidgets('selecting a waste type in the sheet updates the deposit row',
      (tester) async {
    final changes = await openPicker(tester);

    expect(find.text('Botol PET'), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.tap(find.text('Botol PET'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expect(changes.single, {
      'jenis': 'Botol PET',
      'jenis_sampah_id': 'pet',
      'harga': 2000,
      'berat': 2.5,
    });
  });

  testWidgets('name search finds an offscreen waste type without scrolling',
      (tester) async {
    final changes = await openPicker(tester, extraOptions: 40);
    final search = find.widgetWithText(TextField, 'Cari nama jenis sampah');
    expect(find.text('Botol PET'), findsNothing);
    expect(search, findsOneWidget);

    await tester.enterText(search, 'unknown');
    await tester.pumpAndSettle();
    expect(find.text('Jenis sampah tidak ditemukan'), findsOneWidget);

    await tester.enterText(search, '  bOtOl  ');
    await tester.pumpAndSettle();
    expect(find.text('Kertas 0'), findsNothing);
    await tester.tap(find.text('Botol PET'));
    await tester.pumpAndSettle();
    expect(changes.single['jenis_sampah_id'], 'pet');
  });

  testWidgets('category narrows name results and can be cleared',
      (tester) async {
    final changes = await openPicker(tester);
    final search = find.widgetWithText(TextField, 'Cari nama jenis sampah');
    final category = find.byType(DropdownButton<String>);
    expect(category, findsOneWidget);

    await tester.tap(category);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kertas').last);
    await tester.pumpAndSettle();
    expect(find.text('Kardus'), findsOneWidget);
    expect(find.text('Botol PET'), findsNothing);

    await tester.enterText(search, 'botol');
    await tester.pumpAndSettle();
    expect(find.text('Jenis sampah tidak ditemukan'), findsOneWidget);

    await tester.tap(category);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Semua kategori').last);
    await tester.pumpAndSettle();
    expect(find.text('Botol PET'), findsOneWidget);
    expect(find.text('Kardus'), findsNothing);

    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
  });
}
