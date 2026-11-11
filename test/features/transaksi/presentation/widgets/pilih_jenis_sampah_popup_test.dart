import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/layout/side_sheet_presentation.dart';
import 'package:pilah_mobile/features/harga/data/models/harga_model.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/presentation/states/harga_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/item_setoran_card.dart';
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

/// Picker jenis sampah di jendela web yang lebar: sebuah popup di tengah
/// layar, bukan side sheet kedua di atas panel setoran yang juga side sheet.
void main() {
  for (final editing in [false, true]) {
    testWidgets(
        editing
            ? 'wide web opens a centered popup over the open edit dialog'
            : 'wide web opens the picker as a centered popup', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1000, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final changes = <Map<String, dynamic>>[];
      final card = ItemSetoranCard(
        index: 0,
        itemData: editing
            ? const {'berat': 2.5, 'jenis_sampah_id': 'pet'}
            : const {'berat': 2.5},
        hargaFor: editing ? (_) => 800 : null,
        onChanged: changes.add,
        onDelete: () {},
      );
      final router = GoRouter(
        routes: [
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
      await tester.tap(field);
      await tester.pumpAndSettle();

      final picker = find.byType(PilihJenisSampahPicker);
      expect(picker, findsOneWidget);
      expect(ModalRoute.of(tester.element(picker))?.settings,
          isNot(isA<SideSheetPage<HargaEntity>>()));
      expect(find.ancestor(of: picker, matching: find.byType(Dialog)),
          findsOneWidget);
      expect(tester.getRect(picker).center.dx, closeTo(500, 1),
          reason: 'a popup is centered, not docked to the right edge');

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

  testWidgets('Esc closes only the popup and leaves the edit dialog open',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final catalog = _Catalog([
      HargaModel.fromJson({
        'id': 'pet',
        'nama_sampah': 'Botol PET',
        'kategori': 'plastik',
        'harga_per_kg': 2000,
      }),
    ]);
    await tester.pumpWidget(
      withHargaProvider(
        catalog,
        MaterialApp(
          home: Scaffold(
            body: ItemSetoranCard(
              index: 0,
              itemData: const {'berat': 2.5},
              onChanged: (_) {},
              onDelete: () {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('pilih-jenis-sampah')));
    await tester.pumpAndSettle();
    expect(find.byType(PilihJenisSampahPicker), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(PilihJenisSampahPicker), findsNothing);
    expect(find.byKey(const Key('pilih-jenis-sampah')), findsOneWidget);
  });
}
