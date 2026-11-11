import 'package:flutter/material.dart';
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

void main() {
  testWidgets('wide web opens the shared picker at the right edge',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final changes = <Map<String, dynamic>>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: ItemSetoranCard(
              index: 0,
              isWebOverride: true,
              itemData: const {'berat': 2.5},
              onChanged: changes.add,
              onDelete: () {},
            ),
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
    await tester.tap(find.byKey(const Key('pilih-jenis-sampah')));
    await tester.pumpAndSettle();

    final picker = find.byType(PilihJenisSampahPicker);
    expect(picker, findsOneWidget);
    expect(ModalRoute.of(tester.element(picker))?.settings,
        isA<SideSheetPage<HargaEntity>>());
    expect(tester.getRect(picker).center.dx, greaterThan(500));

    await tester.tap(find.byKey(const Key('jenis-sampah-pet')));
    await tester.pumpAndSettle();
    expect(picker, findsNothing);
    expect(changes.single, {
      'berat': 2.5,
      'jenis': 'Botol PET',
      'jenis_sampah_id': 'pet',
      'harga': 2000,
    });
  });
}
