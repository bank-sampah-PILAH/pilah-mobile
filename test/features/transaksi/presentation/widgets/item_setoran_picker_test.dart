import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/harga/data/models/harga_model.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/item_setoran_card.dart';

import '../../../../support/harga_support.dart';
import '../../../../support/stub_api.dart';

class _PickerHargaNotifier extends TestHargaNotifier {
  _PickerHargaNotifier() : super(buildHargaNotifier(StubApi()));

  @override
  List<HargaEntity> get activeJenisSampah => [
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

Future<List<Map<String, dynamic>>> openPicker(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final changes = <Map<String, dynamic>>[];
  await tester.pumpWidget(
    withHargaProvider(
      _PickerHargaNotifier(),
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
}
