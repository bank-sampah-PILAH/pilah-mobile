import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/bases/widgets/activity_item.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_aktivitas_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/aktivitas_selection_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/riwayat_aktivitas_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/states/riwayat_aktivitas_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_list_view.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_selection_bar.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/edit_setoran_sheet.dart';

import '../../../../support/harga_support.dart';
import '../../../../support/stub_api.dart';
import '../../../../support/transaksi_support.dart';

const _path = '/api/v1/transaksi/t1';

class _MockGetAktivitas extends Mock implements GetAktivitasUseCase {}

class _MockExport extends Mock implements ExportTransaksiUseCase {}

class _Feed extends RiwayatAktivitasNotifier {
  _Feed(this.initial) : super(_MockGetAktivitas(), _MockExport());

  final RiwayatAktivitasState initial;
  int loads = 0;

  @override
  RiwayatAktivitasState build() => initial;

  @override
  Future<void> load({bool silent = false, int? pageSize}) async => loads++;
}

Map<String, dynamic> _jenis(String id, String nama, String harga) => {
      'id': id,
      'kode': 'K-$id',
      'nama_sampah': nama,
      'kategori': 'plastik',
      'deskripsi': '',
      'harga_per_kg': harga,
      'is_active': true,
    };

Map<String, dynamic> _detail({
  String catatan = 'awal',
  List? revisi,
  Map<String, String> hargaPadaTanggal = const {'j1': '2000', 'j2': '800'},
}) =>
    {
      'nasabah_nama': 'Budi',
      'tanggal': '2026-10-05T03:00:00Z',
      'total_nilai': '4000',
      'saldo_setelah_transaksi': '4000',
      'status_wa': 'belum_dikirim',
      'catatan': catatan,
      'items': [
        {
          'jenis_sampah_id': 'j1',
          'nama_sampah_snapshot': 'Botol PET',
          'berat': '2.000',
          'harga_snapshot': '2000',
          'subtotal': '4000',
        },
      ],
      'revisi': revisi ?? [],
      'harga_pada_tanggal': hargaPadaTanggal,
    };

ActivitasEntity _setoran(String id, String name) =>
    ActivitasEntity.fromTransaksi(TransaksiEntity(
      id: id,
      initials: 'BU',
      avatarColor: Colors.green.shade100,
      textColor: Colors.green,
      name: name,
      subtitle: 'Botol PET • 2 kg',
      amount: '+Rp 4.000',
      isWaSuccess: false,
      time: '10:00',
      balance: '',
      items: const [],
      tanggal: DateTime(2026, 10, 5, 10),
    ));

void main() {
  late StubApi api;

  setUp(() {
    api = StubApi();
    api.on('GET', '/api/v1/jenis-sampah', json: {
      'results': [
        _jenis('j1', 'Botol PET', '2000'),
        _jenis('j2', 'Kardus', '1000'),
      ],
    });
    api.on('GET', _path, json: _detail());
  });

  Future<ProviderContainer> open(WidgetTester tester) async {
    final harga = buildHargaNotifier(api);
    final transaksi = buildTransaksiNotifier(api);
    final feed = _Feed(const RiwayatAktivitasState());
    late ProviderContainer container;
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(withTransaksiProviders(
      transaksi: transaksi,
      riwayat: feed,
      harga: harga,
      child: MaterialApp(
        home: Consumer(builder: (context, ref, _) {
          container = ProviderScope.containerOf(context);
          return Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showEditSetoranSheet(context, 't1'),
                child: const Text('buka'),
              ),
            ),
          );
        }),
      ),
    ));
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
    return container;
  }

  Finder save() => find.byKey(EditSetoranSheet.saveKey);
  bool saveEnabled(WidgetTester tester) =>
      tester
          .widget<ElevatedButton>(find.descendant(
            of: save(),
            matching: find.byType(ElevatedButton),
          ))
          .onPressed !=
      null;

  testWidgets('summarises the setoran being edited above the form',
      (tester) async {
    api.on('GET', _path,
        json: _detail(revisi: [
          {
            'versi': 1,
            'total_nilai': '2000',
            'catatan': '',
            'alasan': 'Salah timbang',
            'diubah_oleh_nama': 'Ibu Sari',
            'diubah_pada': '2026-10-06T03:00:00Z',
            'items': [],
          },
        ]));
    await open(tester);

    expect(find.text('Budi'), findsOneWidget);
    // The clock depends on the machine's time zone; the date part does not.
    expect(find.textContaining(RegExp(r'^\d+ Oktober 2026, \d{2}:\d{2}$')),
        findsOneWidget);
    expect(find.text('Total Transaksi Ini'), findsOneWidget);
    expect(find.text('Rp 4.000'), findsWidgets);
    expect(find.textContaining('jenis sampah'), findsNothing);
    expect(find.text('Diubah 1 kali'), findsOneWidget);
    expect(find.text('Saldo setelah setoran'), findsOneWidget);
  });

  testWidgets('a setoran never edited does not claim to have been changed',
      (tester) async {
    await open(tester);

    expect(find.textContaining('Diubah'), findsNothing);
  });

  testWidgets('starts from what was recorded and cannot save until changed',
      (tester) async {
    await open(tester);

    expect(find.text('Edit Setoran'), findsOneWidget);
    expect(find.text('Botol PET'), findsWidgets);
    expect(find.widgetWithText(TextField, 'awal'), findsOneWidget);
    expect(saveEnabled(tester), isFalse);

    await tester.enterText(
        find.byKey(EditSetoranSheet.alasanKey), 'Salah timbang');
    await tester.pump();
    expect(saveEnabled(tester), isFalse, reason: 'alasan alone is not an edit');
  });

  testWidgets('a changed weight is sent with the alasan and refreshes the feed',
      (tester) async {
    api.on('PATCH', _path, json: _detail());
    final container = await open(tester);

    await tester.enterText(find.widgetWithText(TextFormField, '2'), '3');
    await tester.enterText(
        find.byKey(EditSetoranSheet.alasanKey), 'Salah timbang');
    await tester.pump();
    expect(saveEnabled(tester), isTrue);

    await tester.ensureVisible(save());
    await tester.tap(save());
    await tester.pumpAndSettle();

    final sent = api.requests.lastWhere((r) => r.method == 'PATCH');
    expect(sent.json, {
      'items': [
        {'jenis_sampah_id': 'j1', 'berat': 3.0}
      ],
      'alasan': 'Salah timbang',
    });
    expect(
        (container.read(riwayatAktivitasProvider.notifier) as _Feed).loads, 1);
    expect(find.text('Edit Setoran'), findsNothing);
  });

  testWidgets('a note-only change sends no items', (tester) async {
    api.on('PATCH', _path, json: _detail(catatan: 'dikoreksi'));
    await open(tester);

    await tester.enterText(
        find.byKey(EditSetoranSheet.catatanKey), 'dikoreksi');
    await tester.enterText(
        find.byKey(EditSetoranSheet.alasanKey), 'Salah ketik');
    await tester.pump();
    await tester.ensureVisible(save());
    await tester.tap(save());
    await tester.pumpAndSettle();

    final sent = api.requests.lastWhere((r) => r.method == 'PATCH');
    expect(sent.json, {'catatan': 'dikoreksi', 'alasan': 'Salah ketik'});
  });

  testWidgets('a refusal from the server is shown and the sheet stays open',
      (tester) async {
    api.on('PATCH', _path,
        status: 409,
        json: {'error': 'Perubahan ini membuat saldo nasabah menjadi negatif'});
    await open(tester);

    await tester.enterText(find.widgetWithText(TextFormField, '2'), '1');
    await tester.enterText(
        find.byKey(EditSetoranSheet.alasanKey), 'Salah timbang');
    await tester.pump();
    await tester.ensureVisible(save());
    await tester.tap(save());
    await tester.pumpAndSettle();

    expect(
        find.textContaining('saldo nasabah menjadi negatif'), findsOneWidget);
    expect(find.text('Edit Setoran'), findsOneWidget);
  });

  testWidgets('a failed load says so and can be retried', (tester) async {
    api.on('GET', _path, status: 500, json: {});
    await open(tester);

    expect(find.text('Rincian setoran gagal dimuat.'), findsOneWidget);

    api.on('GET', _path, json: _detail());
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Rincian setoran gagal dimuat.'), findsNothing);
    expect(find.text('Botol PET'), findsWidgets);
  });

  testWidgets('an item can be added and removed again', (tester) async {
    await open(tester);

    await tester.ensureVisible(find.text('Tambah Item'));
    await tester.tap(find.text('Tambah Item'));
    await tester.pump();
    expect(find.text('Pilih Jenis'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pump();
    expect(find.text('Pilih Jenis'), findsNothing);
  });

  testWidgets('choosing a jenis that is already listed warns instead',
      (tester) async {
    await open(tester);

    await tester.ensureVisible(find.text('Tambah Item'));
    await tester.tap(find.text('Tambah Item'));
    await tester.pump();
    final dropdown = find.byType(DropdownButton<String>).last;
    await tester.ensureVisible(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Botol PET').last);
    // Not pumpAndSettle: it would run on until the toast dismisses itself.
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Jenis Sudah Dipilih'), findsOneWidget);
    expect(find.text('Pilih Jenis'), findsOneWidget);
  });

  Future<void> addKardus(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Tambah Item'));
    await tester.tap(find.text('Tambah Item'));
    await tester.pump();
    final dropdown = find.byType(DropdownButton<String>).last;
    await tester.ensureVisible(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kardus').last);
    await tester.pumpAndSettle();
  }

  testWidgets('a jenis added to an old setoran is priced as on its date',
      (tester) async {
    await open(tester);

    await addKardus(tester);

    // Kardus costs 1.000 today but was 800 when the setoran was recorded.
    expect(find.text('800'), findsOneWidget);
    expect(find.text('1.000'), findsNothing);
  });

  testWidgets('a jenis with no price on the setoran date gets none',
      (tester) async {
    api.on('GET', _path, json: _detail(hargaPadaTanggal: const {'j1': '2000'}));
    await open(tester);

    await addKardus(tester);

    expect(find.text('1.000'), findsNothing);
    expect(find.text('800'), findsNothing);
  });

  group('selection on the phone feed', () {
    Future<ProviderContainer> pumpFeed(WidgetTester tester) async {
      final transaksi = buildTransaksiNotifier(api);
      final feed = _Feed(RiwayatAktivitasState(
        status: AktivitasStatus.loaded,
        items: [_setoran('t1', 'Budi'), _setoran('t2', 'Sari')],
        totalCount: 2,
      ));
      late ProviderContainer container;
      final router = GoRouter(routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => withTransaksiProviders(
            transaksi: transaksi,
            riwayat: feed,
            harga: buildHargaNotifier(api),
            child: Consumer(builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              final selecting = ref.watch(aktivitasSelectionProvider) != null;
              return Scaffold(
                body: Column(children: [
                  if (selecting)
                    AktivitasSelectionBar(
                      onEdit: (id) => showEditSetoranSheet(context, id),
                    ),
                  const Expanded(child: AktivitasListView(isWeb: false)),
                ]),
              );
            }),
          ),
        ),
      ]);
      addTearDown(router.dispose);
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(withTransaksiProviders(
        transaksi: transaksi,
        riwayat: feed,
        harga: buildHargaNotifier(api),
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pump();
      return container;
    }

    Future<void> hold(WidgetTester tester, String name) async {
      final gesture =
          await tester.startGesture(tester.getCenter(find.text(name)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await gesture.up();
      await tester.pump();
    }

    testWidgets('holding a row selects it and opens the header with Edit',
        (tester) async {
      await pumpFeed(tester);
      expect(find.byKey(AktivitasSelectionBar.editKey), findsNothing);

      await hold(tester, 'Budi');

      expect(find.text('1 dipilih'), findsOneWidget);
      expect(find.byKey(AktivitasSelectionBar.editKey), findsOneWidget);
      expect(
          find.byKey(const ValueKey('aktivitas-row-selected')), findsOneWidget);
    });

    testWidgets('Edit in the header is a labelled, rounded button',
        (tester) async {
      await pumpFeed(tester);
      await hold(tester, 'Budi');

      final button = find.byKey(AktivitasSelectionBar.editKey);
      expect(button, findsOneWidget);
      expect(find.descendant(of: button, matching: find.text('Edit')),
          findsOneWidget);
      expect(tester.widget(button), isA<AppButton>());
    });

    testWidgets('the header Edit is green on white, like the web button',
        (tester) async {
      await pumpFeed(tester);
      await hold(tester, 'Budi');

      final button =
          tester.widget<AppButton>(find.byKey(AktivitasSelectionBar.editKey));
      expect(button.variant, AppButtonVariant.outlined);
      final white = find.ancestor(
        of: find.byKey(AktivitasSelectionBar.editKey),
        matching: find.byWidgetPredicate((w) =>
            w is DecoratedBox &&
            (w.decoration as BoxDecoration).color == Colors.white),
      );
      expect(white, findsOneWidget);
    });

    testWidgets('the selected tint reaches past the row content',
        (tester) async {
      await pumpFeed(tester);
      await hold(tester, 'Budi');

      final tint = tester
          .getRect(find.byKey(const ValueKey('aktivitas-row-selected-tint')));
      final content = tester.getRect(find.byType(ActivityItem).first);
      expect(content.left - tint.left, greaterThanOrEqualTo(8));
      expect(tint.right - content.right, greaterThanOrEqualTo(8));
    });

    testWidgets(
        'only one setoran can be selected: tapping another moves the choice',
        (tester) async {
      final container = await pumpFeed(tester);
      await hold(tester, 'Budi');

      await tester.tap(find.text('Sari'));
      await tester.pump();

      expect(find.text('1 dipilih'), findsOneWidget);
      expect(
          find.byKey(const ValueKey('aktivitas-row-selected')), findsOneWidget);
      expect(container.read(aktivitasSelectionProvider), 't2');
      expect(find.byKey(AktivitasSelectionBar.editKey), findsOneWidget);
    });

    testWidgets('tapping the selected row again leaves the selection mode',
        (tester) async {
      final container = await pumpFeed(tester);
      await hold(tester, 'Budi');

      await tester.tap(find.text('Budi'));
      await tester.pump();

      expect(container.read(aktivitasSelectionProvider), isNull);
      expect(find.text('1 dipilih'), findsNothing);
    });

    testWidgets(
        'releasing the last selection or the close button leaves the mode',
        (tester) async {
      final container = await pumpFeed(tester);
      await hold(tester, 'Budi');

      await tester.tap(find.byKey(AktivitasSelectionBar.closeKey));
      await tester.pump();

      expect(container.read(aktivitasSelectionProvider), isNull);
      expect(find.text('1 dipilih'), findsNothing);
    });

    testWidgets('Edit opens the edit sheet for the selected setoran',
        (tester) async {
      await pumpFeed(tester);
      await hold(tester, 'Budi');

      await tester.tap(find.byKey(AktivitasSelectionBar.editKey));
      await tester.pumpAndSettle();

      expect(find.text('Edit Setoran'), findsOneWidget);
      expect(api.requests.any((r) => r.method == 'GET' && r.path == _path),
          isTrue);
    });
  });

  group('Aksi column on a wide screen', () {
    Future<void> pumpTable(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final feed = _Feed(RiwayatAktivitasState(
        status: AktivitasStatus.loaded,
        items: [_setoran('t1', 'Budi')],
        totalCount: 1,
      ));
      await tester.pumpWidget(withTransaksiProviders(
        transaksi: buildTransaksiNotifier(api),
        riwayat: feed,
        harga: buildHargaNotifier(api),
        child: const MaterialApp(
          home: Scaffold(body: AktivitasListView(isWeb: true)),
        ),
      ));
      await tester.pump();
    }

    testWidgets('a setoran row has an Edit button that opens the form',
        (tester) async {
      await pumpTable(tester);

      expect(find.text('AKSI'), findsOneWidget);
      final button = find.byKey(const ValueKey('aktivitas-edit'));
      expect(tester.widget(button), isA<AppButton>());
      expect(find.descendant(of: button, matching: find.text('Edit')),
          findsOneWidget);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('Edit Setoran'), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('the Edit button keeps clear of the nominal column',
        (tester) async {
      await pumpTable(tester);

      final nominal = tester.getRect(find.text('+Rp 4.000'));
      final edit = tester.getRect(find.byKey(const ValueKey('aktivitas-edit')));
      final aksi = tester.getRect(find.text('AKSI'));

      expect(edit.left - nominal.right, greaterThanOrEqualTo(32));
      expect(aksi.left, edit.left, reason: 'the header sits over the button');
    });

    testWidgets('holding a table row does not start a selection',
        (tester) async {
      await pumpTable(tester);

      final gesture =
          await tester.startGesture(tester.getCenter(find.text('Budi')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.byKey(AktivitasSelectionBar.editKey), findsNothing);
    });
  });
}
