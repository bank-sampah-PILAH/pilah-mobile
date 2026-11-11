import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/harga/data/models/harga_model.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/presentation/states/harga_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/item_setoran_card.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/jenis_sampah_side_sheet.dart';

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

HargaEntity _jenis(String id, String nama, int harga) => HargaModel.fromJson({
      'id': id,
      'nama_sampah': nama,
      'kategori': 'plastik',
      'harga_per_kg': harga,
    });

/// Picker dibuka dari kartu item, sehingga setiap wadah (bottom sheet, dialog,
/// side sheet web) dicoba lewat jalur yang sama dengan yang dipakai pengguna.
const _wadah = <String, ({double width, bool isWeb})>{
  'bottom sheet': (width: 400, isWeb: false),
  'dialog': (width: 800, isWeb: false),
  'side sheet web': (width: 1000, isWeb: true),
};

Future<void> _bukaPicker(
  WidgetTester tester, {
  required double width,
  required bool isWeb,
  int Function(HargaEntity jenis)? hargaFor,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 800);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    routes: [
      jenisSampahSideSheetRoute(),
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: ItemSetoranCard(
            index: 0,
            isWebOverride: isWeb,
            itemData: const {'berat': 1.0},
            hargaFor: hargaFor,
            onChanged: (_) {},
            onDelete: () {},
          ),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  final catalog = _Catalog([
    _jenis('pet', 'Botol PET', 2000),
    _jenis('kaca', 'Botol Kaca', 500),
  ]);
  await tester.pumpWidget(
    withHargaProvider(catalog, MaterialApp.router(routerConfig: router)),
  );
  await tester.tap(find.byKey(const Key('pilih-jenis-sampah')));
  await tester.pumpAndSettle();
}

Finder _hargaBaris(String id, String teks) => find.descendant(
    of: find.byKey(Key('jenis-sampah-$id')), matching: find.text(teks));

void main() {
  for (final entry in _wadah.entries) {
    group('picker di ${entry.key}', () {
      testWidgets('saat membuat, baris memakai harga hari ini', (tester) async {
        await _bukaPicker(tester,
            width: entry.value.width, isWeb: entry.value.isWeb);

        expect(_hargaBaris('pet', 'Rp 2.000/kg'), findsOneWidget);
        expect(_hargaBaris('kaca', 'Rp 500/kg'), findsOneWidget);
      });

      testWidgets(
          'saat mengedit setoran lampau, baris memakai harga yang akan disimpan',
          (tester) async {
        await _bukaPicker(
          tester,
          width: entry.value.width,
          isWeb: entry.value.isWeb,
          hargaFor: (jenis) => jenis.id == 'pet' ? 800 : 300,
        );

        expect(_hargaBaris('pet', 'Rp 800/kg'), findsOneWidget);
        expect(_hargaBaris('kaca', 'Rp 300/kg'), findsOneWidget);
        expect(find.text('Rp 2.000/kg'), findsNothing);
      });

      testWidgets(
          'jenis tanpa harga pada tanggal itu tidak ditampilkan sebagai Rp 0',
          (tester) async {
        await _bukaPicker(
          tester,
          width: entry.value.width,
          isWeb: entry.value.isWeb,
          hargaFor: (jenis) => jenis.id == 'pet' ? 800 : 0,
        );

        expect(_hargaBaris('pet', 'Rp 800/kg'), findsOneWidget);
        expect(_hargaBaris('kaca', 'Belum ada harga'), findsOneWidget);
        expect(
          find.descendant(
              of: find.byKey(const Key('jenis-sampah-kaca')),
              matching: find.textContaining('Rp')),
          findsNothing,
        );
        expect(find.text('Rp 500/kg'), findsNothing);
      });
    });
  }
}
