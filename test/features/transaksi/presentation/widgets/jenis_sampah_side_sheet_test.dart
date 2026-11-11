import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/layout/side_sheet_presentation.dart';
import 'package:pilah_mobile/features/harga/data/models/harga_model.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/presentation/states/harga_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/item_setoran_card.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/jenis_sampah_side_sheet.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/pilih_jenis_sampah_picker.dart';

import '../../../../support/harga_support.dart';
import '../../../../support/stub_api.dart';

class _Catalog extends TestHargaNotifier {
  _Catalog(this.items)
      : super(buildHargaNotifier(StubApi()),
            initialState: HargaLoaded(jenisSampahList: items));

  final List<HargaEntity> items;

  @override
  List<HargaEntity> get activeJenisSampah => items;
}

void main() {
  for (final editing in [false, true]) {
    testWidgets(
        editing
            ? 'the side sheet returns to the open edit dialog with historical price'
            : 'wide web opens the shared picker at the right edge',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1000, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final changes = <Map<String, dynamic>>[];
      final card = ItemSetoranCard(
        index: 0,
        isWebOverride: true,
        itemData: editing
            ? const {'berat': 2.5, 'jenis_sampah_id': 'pet'}
            : const {'berat': 2.5},
        hargaFor: editing ? (_) => 800 : null,
        onChanged: changes.add,
        onDelete: () {},
      );
      final router = GoRouter(
        routes: [
          jenisSampahSideSheetRoute(),
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: editing
                  ? TextButton(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (context) => Dialog(child: card),
                      ),
                      child: const Text('Edit setoran'),
                    )
                  : card,
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      final catalog = _Catalog([
        HargaModel.fromJson({
          'id': 'pet',
          'nama_sampah': 'Botol PET',
          'kategori': 'plastik',
          'harga_per_kg': 2000,
        }),
      ]);
      await tester.pumpWidget(
        withHargaProvider(catalog, MaterialApp.router(routerConfig: router)),
      );
      if (editing) {
        await tester.tap(find.text('Edit setoran'));
        await tester.pumpAndSettle();
      }
      final field = find.byKey(const Key('pilih-jenis-sampah'));
      if (editing) {
        expect(find.descendant(of: field, matching: find.text('Botol PET')),
            findsOneWidget);
      }
      await tester.tap(field);
      await tester.pumpAndSettle();

      final picker = find.byType(PilihJenisSampahPicker);
      expect(picker, findsOneWidget);
      expect(ModalRoute.of(tester.element(picker))?.settings,
          isA<SideSheetPage<HargaEntity>>());
      expect(tester.getRect(picker).center.dx, greaterThan(500));

      final option = find.byKey(const Key('jenis-sampah-pet'));
      if (editing) {
        expect(find.descendant(of: option, matching: find.byIcon(Icons.check)),
            findsOneWidget);
      }
      await tester.tap(option);
      await tester.pumpAndSettle();
      expect(picker, findsNothing);
      expect(field.hitTestable(), findsOneWidget);
      expect(changes.single, {
        'berat': 2.5,
        'jenis': 'Botol PET',
        'jenis_sampah_id': 'pet',
        'harga': editing ? 800 : 2000,
      });
    });
  }
}
