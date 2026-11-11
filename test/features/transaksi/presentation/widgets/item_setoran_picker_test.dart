import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/bases/widgets/bottom_sheet_header.dart';
import 'package:pilah_mobile/features/harga/data/models/harga_model.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/presentation/states/harga_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/item_setoran_card.dart';

import '../../../../support/harga_support.dart';
import '../../../../support/stub_api.dart';

class _PickerHargaNotifier extends TestHargaNotifier {
  _PickerHargaNotifier(this.extraOptions, {bool loading = false})
      : super(buildHargaNotifier(StubApi()),
            initialState: loading ? HargaLoading() : HargaInitial());

  void finishLoading() => state = const HargaLoaded(jenisSampahList: []);

  final int extraOptions;
  bool emptyCatalog = false;

  void replaceState(HargaState next) => state = next;

  @override
  List<HargaEntity> get activeJenisSampah =>
      state is HargaLoading || state is HargaError || emptyCatalog
          ? []
          : [
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

Future<List<Map<String, dynamic>>> _openPicker(
  WidgetTester tester, {
  int extraOptions = 0,
  double width = 400,
  _PickerHargaNotifier? notifier,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 800);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final changes = <Map<String, dynamic>>[];
  await tester.pumpWidget(
    withHargaProvider(
      notifier ?? _PickerHargaNotifier(extraOptions),
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
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return changes;
}

void main() {
  testWidgets('selecting a waste type in the sheet updates the deposit row',
      (tester) async {
    final changes = await _openPicker(tester);

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

  testWidgets('the picker uses dismissal controls for its presentation',
      (tester) async {
    final phoneChanges = await _openPicker(tester);
    final handle = find.byKey(BottomSheetHeader.dragHandleKey);
    final close = find.descendant(
      of: find.byType(BottomSheetHeader),
      matching: find.byIcon(Icons.close),
    );
    expect(handle, findsOneWidget);
    expect(close, findsNothing);
    await tester.drag(handle, const Offset(0, 700));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(phoneChanges, isEmpty);

    final wideChanges = await _openPicker(tester, width: 1000);
    expect(find.byType(Dialog), findsOneWidget);
    expect(handle, findsNothing);
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(wideChanges, isEmpty);
  });

  testWidgets('search resets scroll without remounting the results',
      (tester) async {
    await _openPicker(tester, extraOptions: 40);
    final list = find.byType(ListView);
    final scrollable =
        find.descendant(of: list, matching: find.byType(Scrollable));
    final state = tester.state<ScrollableState>(scrollable);
    await tester.drag(list, const Offset(0, -320));
    await tester.pumpAndSettle();
    expect(state.position.pixels, greaterThan(0));

    await tester.enterText(
      find.widgetWithText(TextField, 'Cari nama jenis sampah'),
      'kertas',
    );
    await tester.pumpAndSettle();

    expect(tester.state<ScrollableState>(scrollable), same(state));
    expect(state.position.pixels, 0);
    expect(find.text('Kertas 0'), findsOneWidget);
  });

  testWidgets('name search finds an offscreen waste type without scrolling',
      (tester) async {
    final changes = await _openPicker(tester, extraOptions: 40);
    final search = find.widgetWithText(TextField, 'Cari nama jenis sampah');
    expect(find.text('Botol PET'), findsNothing);
    expect(search, findsOneWidget);

    await tester.enterText(search, 'unknown');
    await tester.pumpAndSettle();
    expect(find.text('Jenis sampah tidak ditemukan'), findsOneWidget);

    await tester.enterText(search, '  bOtOl  ');
    await tester.pumpAndSettle();
    expect(find.text('Kertas 0'), findsNothing);
    expect(find.text('Botol PET'), findsOneWidget);
    await tester.tap(find.text('Botol PET'));
    await tester.pumpAndSettle();
    expect(changes.single['jenis_sampah_id'], 'pet');
  });

  testWidgets('category narrows name results and can be cleared',
      (tester) async {
    final changes = await _openPicker(tester);
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

  testWidgets('an open picker shows options when the catalog finishes loading',
      (tester) async {
    final notifier = _PickerHargaNotifier(0, loading: true);
    final changes = await _openPicker(tester, notifier: notifier);
    expect(find.text('Botol PET'), findsNothing);

    notifier.finishLoading();
    await tester.pumpAndSettle();
    expect(find.text('Botol PET'), findsOneWidget);
    await tester.tap(find.text('Botol PET'));
    await tester.pumpAndSettle();
    expect(changes.single['jenis_sampah_id'], 'pet');
  });

  testWidgets('picker distinguishes an unavailable catalog from an empty one',
      (tester) async {
    final notifier = _PickerHargaNotifier(0, loading: true);
    final changes = await _openPicker(tester, notifier: notifier);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    notifier.replaceState(const HargaError('Gagal memuat jenis sampah'));
    await tester.pumpAndSettle();
    expect(find.text('Gagal memuat jenis sampah'), findsOneWidget);
    expect(find.text('Belum ada jenis sampah aktif'), findsNothing);

    notifier.emptyCatalog = true;
    notifier.finishLoading();
    await tester.pumpAndSettle();
    expect(find.text('Belum ada jenis sampah aktif'), findsOneWidget);
    expect(find.text('Gagal memuat jenis sampah'), findsNothing);
    expect(changes, isEmpty);
  });
}
