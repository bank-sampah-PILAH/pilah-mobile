import 'package:pilah_mobile/design/widgets/app_sheet_handle.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/layout/web_pagination_bar.dart';
import 'package:pilah_mobile/design/widgets/app_chip.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';
import 'package:pilah_mobile/features/harga/presentation/pages/harga_page.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/widgets/app_tappable_card.dart';
import 'package:pilah_mobile/features/harga/data/datasources/harga_remote_data_source_impl.dart';
import 'package:pilah_mobile/features/harga/data/repositories/harga_repository_impl.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/get_riwayat_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/riwayat_harga_cubit.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/harga_detail_flow.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/harga_detail_sheet.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/harga_table.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/jenis_sampah_form.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/tambah_jenis_sampah_bottom_sheet.dart';

import '../../../../support/harga_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

Map<String, dynamic> _row(String id, String nama,
        {bool active = true, String kategori = 'plastik'}) =>
    {
      'id': id,
      'kode': 'K-$id',
      'nama_sampah': nama,
      'kategori': kategori,
      'deskripsi': 'desk $nama',
      'harga_per_kg': '2500',
      'is_active': active,
    };

/// Blok `medium`: form tetap sebuah bottom sheet, seperti di telepon.
const _medium = Size(800, 1600);

/// Blok `expanded`: form muncul sebagai panel di samping daftar.
const _expanded = Size(1440, 900);

void main() {
  late StubApi api;
  late HargaCubit cubit;

  Future<void> openPage(WidgetTester tester,
      {Size size = _medium, bool isWeb = kIsWeb}) async {
    await pumpRouted(
      tester,
      BlocProvider<HargaCubit>.value(
          value: cubit, child: HargaPage(isWeb: isWeb)),
      size: size,
    );
    if (kIsWeb) await pumpReal(tester);
    await tester.pumpAndSettle();
  }

  /// Mengetuk baris, lalu memilih Edit di detailnya.
  Future<void> editJenis(WidgetTester tester, String name) async {
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
  }

  setUp(() {
    api = StubApi();
    if (di.isRegistered<RiwayatHargaCubit>()) {
      di.unregister<RiwayatHargaCubit>();
    }
    di.registerFactory<RiwayatHargaCubit>(() => RiwayatHargaCubit(
        GetRiwayatHargaUseCase(
            HargaRepositoryImpl(HargaRemoteDataSourceImpl(api.network)))));
    cubit = buildHargaCubit(api);
    api.on('GET', '/api/v1/jenis-sampah', json: {
      'results': [
        _row('1', 'Botol PET'),
        _row('2', 'Kardus', kategori: 'kertas'),
        _row('3', 'Kaleng', active: false, kategori: 'logam'),
      ],
    });
  });

  tearDown(() async {
    await cubit.close();
    if (di.isRegistered<RiwayatHargaCubit>()) {
      await di.unregister<RiwayatHargaCubit>();
    }
  });

  testWidgets('below expanded a row opens a detail dialog, with history in it',
      (tester) async {
    api.on('GET', '/api/v1/jenis-sampah/1/harga', json: {
      'results': [
        {
          'id': 1,
          'harga_per_kg': '3500.00',
          'satuan': 'kg',
          'berlaku_mulai': '2026-09-01T03:00:00Z',
          'dibuat_oleh': null,
          'status': 'berlaku',
        },
      ],
    });
    await openPage(tester);

    await tester.tap(find.text('Botol PET'));
    await tester.pumpAndSettle();
    expect(find.byType(HargaDetailFlow), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget,
        reason: 'a sheet as wide as the window looks wrong on the web');
    expect(find.byType(AppSheetHandle), findsNothing,
        reason: 'a dialog cannot be dragged');
    expect(find.byType(TambahJenisSampahBottomSheet), findsNothing);

    await tester.tap(find.text('Riwayat harga'));
    await tester.pumpAndSettle();
    expect(find.text('Rp 3.500 / kg'), findsOneWidget);
    expect(find.text('Berlaku sekarang'), findsOneWidget);

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget, reason: 'back to the detail');
  });

  testWidgets('on a wide screen a row opens a side panel, not a dialog',
      (tester) async {
    await openPage(tester, size: _expanded);

    await tester.tap(find.text('Botol PET'));
    await tester.pumpAndSettle();

    expect(find.text('Detail jenis sampah'), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(HargaTable), findsOneWidget,
        reason: 'the table stays beside the panel');
    expect(find.text('Kardus'), findsOneWidget);
  });

  testWidgets('the panel goes detail, edit, and back to detail',
      (tester) async {
    await openPage(tester, size: _expanded);
    await tester.tap(find.text('Botol PET'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.byType(JenisSampahForm), findsOneWidget);

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    expect(find.byType(JenisSampahForm), findsNothing);
    expect(find.byType(HargaDetailSheet), findsOneWidget);
  });

  testWidgets('in the panel history opens in place and returns to the detail',
      (tester) async {
    api.on('GET', '/api/v1/jenis-sampah/1/harga',
        json: {'results': <Object>[]});
    await openPage(tester, size: _expanded);
    await tester.tap(find.text('Botol PET'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Riwayat harga'));
    await tester.pumpAndSettle();
    expect(find.text('Belum Ada Riwayat Harga'), findsOneWidget);

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    expect(find.byType(HargaDetailSheet), findsOneWidget);
  });

  testWidgets('the panel has one header whose title follows the view',
      (tester) async {
    api.on('GET', '/api/v1/jenis-sampah/1/harga',
        json: {'results': <Object>[]});
    await openPage(tester, size: _expanded);
    await tester.tap(find.text('Botol PET'));
    await tester.pumpAndSettle();

    // Detail: the jenis is the title; no back, only close.
    expect(find.byTooltip('Kembali'), findsNothing);
    expect(find.byTooltip('Tutup'), findsOneWidget);

    await tester.tap(find.text('Riwayat harga'));
    await tester.pumpAndSettle();
    expect(find.text('Riwayat harga'), findsOneWidget);
    expect(find.text('Detail jenis sampah'), findsNothing);
    expect(find.byTooltip('Kembali'), findsOneWidget);
    expect(find.byTooltip('Tutup'), findsOneWidget);

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Jenis Sampah'), findsOneWidget);
    expect(find.byTooltip('Kembali'), findsOneWidget);
    expect(find.byTooltip('Tutup'), findsOneWidget);
  });

  testWidgets('Esc closes the panel', (tester) async {
    await openPage(tester, size: _expanded);
    await tester.tap(find.text('Botol PET'));
    await tester.pumpAndSettle();
    expect(find.byType(HargaDetailSheet), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(HargaDetailSheet), findsNothing);
  });

  testWidgets('the sheet below expanded has back but no close button',
      (tester) async {
    api.on('GET', '/api/v1/jenis-sampah/1/harga',
        json: {'results': <Object>[]});
    await openPage(tester);
    await tester.tap(find.text('Botol PET'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Tutup'), findsNothing);

    await tester.tap(find.text('Riwayat harga'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Kembali'), findsOneWidget);
    expect(find.byTooltip('Tutup'), findsNothing);
  });

  testWidgets('choosing another row starts from its detail', (tester) async {
    api.on('GET', '/api/v1/jenis-sampah/1/harga',
        json: {'results': <Object>[]});
    await openPage(tester, size: _expanded);
    await tester.tap(find.text('Botol PET'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Riwayat harga'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kardus'));
    await tester.pumpAndSettle();

    expect(find.byType(HargaDetailSheet), findsOneWidget);
    expect(find.text('Belum Ada Riwayat Harga'), findsNothing);
  });

  testWidgets('Edit in the detail opens the edit sheet below expanded',
      (tester) async {
    await openPage(tester);

    await editJenis(tester, 'Botol PET');

    expect(find.byType(HargaDetailSheet), findsNothing);
    expect(find.byType(TambahJenisSampahBottomSheet), findsOneWidget);
  });

  testWidgets('the price is the most prominent text on a card', (tester) async {
    await openPage(tester, size: const Size(420, 1400));

    double size(Finder f) => tester.widget<Text>(f.first).style!.fontSize ?? 14;
    expect(
        size(find.text('Rp 2.500')), greaterThan(size(find.text('Botol PET'))));
  });

  testWidgets('a card has no chevron: the whole card opens the detail',
      (tester) async {
    await openPage(tester, size: const Size(420, 1400));

    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('a long name and description stay on one line each',
      (tester) async {
    api.on('GET', '/api/v1/jenis-sampah', json: {
      'results': [
        _row('9', 'Botol plastik bening berukuran sangat besar sekali'),
      ],
    });
    await openPage(tester, size: const Size(360, 1400));

    expect(tester.takeException(), isNull);
    final name = tester.widget<Text>(
        find.text('Botol plastik bening berukuran sangat besar sekali'));
    expect(name.maxLines, 1);
    expect(name.overflow, TextOverflow.ellipsis);
  });

  testWidgets('a card no longer carries its own history link', (tester) async {
    await openPage(tester);

    expect(find.text('Riwayat harga'), findsNothing);
  });

  testWidgets(
      'a wide screen puts the search beside the title on the web gutter',
      (tester) async {
    await openPage(tester, size: const Size(1000, 900));

    final title = tester.getRect(find.text('Jenis Sampah & Harga'));
    final search = tester.getRect(find.byType(TextField));
    expect(title.left, 32);
    expect(search.width, 360);
    expect(search.left, greaterThan(title.right));
    expect(search.top, lessThan(title.bottom));
  });

  testWidgets('lists active jenis sampah with their price', (tester) async {
    await openPage(tester);

    expect(find.text('Jenis Sampah & Harga'), findsOneWidget);
    expect(find.text('Botol PET'), findsOneWidget);
    expect(find.text('Kardus'), findsOneWidget);
    expect(find.text('Kaleng'), findsNothing);
    expect(find.text('Rp 2.500'), findsNWidgets(2));
  });

  testWidgets('web harga table paginates and search returns to page one',
      (tester) async {
    api.on('GET', '/api/v1/jenis-sampah', json: {
      'results': [for (var i = 1; i <= 12; i++) _row('$i', 'Jenis $i')],
    });
    await openPage(tester, size: _expanded, isWeb: true);
    await tester.pumpAndSettle();

    HargaTable table() => tester.widget<HargaTable>(find.byType(HargaTable));
    expect(find.byType(WebPaginationBar), findsOneWidget);
    // The bar is the card's footer, not a footer of the page below it.
    final card = tester.getRect(find.byType(HargaTable));
    final bar = tester.getRect(find.byType(WebPaginationBar));
    expect(bar.bottom, lessThanOrEqualTo(card.bottom));
    expect(bar.top, greaterThan(card.top));
    expect(find.text('Menampilkan 1–10 dari 12 jenis sampah'), findsOneWidget);
    expect(table().items.map((item) => item.name),
        [for (var i = 1; i <= 10; i++) 'Jenis $i']);

    await tester.tap(find.bySemanticsLabel('Halaman 2'));
    await tester.pumpAndSettle();
    expect(find.text('Menampilkan 11–12 dari 12 jenis sampah'), findsOneWidget);
    expect(table().items.map((item) => item.name), ['Jenis 11', 'Jenis 12']);

    await tester.enterText(find.byType(TextField).first, 'Jenis');
    await tester.pumpAndSettle();
    expect(find.text('Menampilkan 1–10 dari 12 jenis sampah'), findsOneWidget);
    expect(table().items.map((item) => item.name),
        [for (var i = 1; i <= 10; i++) 'Jenis $i']);
  });

  testWidgets('compact web paginates cards', (tester) async {
    api.on('GET', '/api/v1/jenis-sampah', json: {
      'results': [for (var i = 1; i <= 12; i++) _row('$i', 'Jenis $i')],
    });
    await openPage(tester, size: const Size(500, 844), isWeb: true);
    await tester.pumpAndSettle();

    expect(find.byType(WebPaginationBar), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byTooltip('Tambah Jenis Sampah'), findsOneWidget);
    expect(find.text('Menampilkan 1–10 dari 12 jenis sampah'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Halaman 2'));
    await tester.pumpAndSettle();
    expect(find.text('Jenis 11'), findsOneWidget);
    expect(find.text('Jenis 1'), findsNothing);

    await tester.tap(find.byTooltip('Tambah Jenis Sampah'));
    await tester.pumpAndSettle();
    expect(find.byType(TambahJenisSampahBottomSheet), findsOneWidget);
  });

  testWidgets('the Aktif and Tidak Aktif chips announce which one is selected',
      (tester) async {
    final handle = tester.ensureSemantics();
    await openPage(tester);
    Finder chip(String label) => find.ancestor(
          of: find.text(label),
          matching: find.byType(AppChip),
        );

    expect(
      tester.getSemantics(chip('Aktif')),
      isSemantics(isButton: true, hasSelectedState: true, isSelected: true),
    );
    expect(
      tester.getSemantics(chip('Tidak Aktif')),
      isSemantics(hasSelectedState: true, isSelected: false),
    );
    handle.dispose();
  });

  testWidgets('a price card is announced as a button', (tester) async {
    final handle = tester.ensureSemantics();
    await openPage(tester, size: const Size(420, 1400));

    expect(
      tester.getSemantics(find.text('Botol PET')),
      isSemantics(isButton: true, hasTapAction: true),
    );
    handle.dispose();
  });

  testWidgets('the Tidak Aktif chip switches to deactivated items',
      (tester) async {
    await openPage(tester);

    await tester.tap(find.text('Tidak Aktif'));
    await tester.pumpAndSettle();
    expect(find.text('Kaleng'), findsOneWidget);
    expect(find.text('Botol PET'), findsNothing);

    await tester.tap(find.text('Aktif'));
    await tester.pumpAndSettle();
    expect(find.text('Botol PET'), findsOneWidget);
  });

  testWidgets('search filters, and an empty result says nothing matched',
      (tester) async {
    await openPage(tester);

    await tester.enterText(find.byType(TextField).first, 'kardus');
    await tester.pumpAndSettle();
    expect(find.text('Kardus'), findsOneWidget);
    expect(find.text('Botol PET'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('Jenis Sampah Tidak Ditemukan'), findsOneWidget);
  });

  testWidgets('empty tabs explain themselves', (tester) async {
    api.on('GET', '/api/v1/jenis-sampah', json: {'results': []});
    await openPage(tester);
    expect(find.text('Belum Ada Jenis Sampah'), findsOneWidget);

    await tester.tap(find.text('Tidak Aktif'));
    await tester.pumpAndSettle();
    expect(find.text('Tidak Ada Jenis Nonaktif'), findsOneWidget);
  });

  testWidgets('a failed load names the failure and offers a retry button',
      (tester) async {
    api.on('GET', '/api/v1/jenis-sampah',
        status: 400, json: {'error': 'Server sibuk'});
    await openPage(tester);
    expect(find.text('Server sibuk'), findsOneWidget);

    api.on('GET', '/api/v1/jenis-sampah', json: {
      'results': [_row('1', 'Botol PET')],
    });
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Botol PET'), findsOneWidget);
  });

  testWidgets('a failed load can also be retried by pulling down',
      (tester) async {
    api.on('GET', '/api/v1/jenis-sampah',
        status: 400, json: {'error': 'Server sibuk'});
    await openPage(tester);

    api.on('GET', '/api/v1/jenis-sampah', json: {
      'results': [_row('1', 'Botol PET')],
    });
    await tester.fling(find.text('Server sibuk'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Botol PET'), findsOneWidget);
  });

  testWidgets('shows skeletons until the first load completes', (tester) async {
    await pumpRouted(
      tester,
      BlocProvider<HargaCubit>.value(value: cubit, child: const HargaPage()),
      size: const Size(800, 1600),
    );
    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('Botol PET'), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('the add button opens the empty form', (tester) async {
    await openPage(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(TambahJenisSampahBottomSheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TambahJenisSampahBottomSheet),
        matching: find.text('Tambah Jenis Sampah'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping a card opens the edit form prefilled', (tester) async {
    await openPage(tester);

    await editJenis(tester, 'Botol PET');

    expect(find.text('Edit Jenis Sampah'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Botol PET'), findsOneWidget);
  });

  // On a desktop window the same form becomes a panel beside the list, so the
  // list stays readable while a price is edited. Only expanded gets it: at
  // medium the panel would be about 320px, too narrow for this form, which is
  // the same rule the jadwal page follows.
  testWidgets('on a desktop window the add button opens a panel, not a sheet',
      (tester) async {
    await openPage(tester, size: _expanded);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(JenisSampahForm), findsOneWidget);
    expect(
      find.byType(TambahJenisSampahBottomSheet),
      findsNothing,
      reason: 'a panel must not also be hosted in a sheet',
    );
    expect(
      find.text('Botol PET'),
      findsOneWidget,
      reason: 'the list stays visible beside the form; that is the point',
    );
  });

  testWidgets('on a desktop window tapping a card fills the panel',
      (tester) async {
    await openPage(tester, size: _expanded);

    await editJenis(tester, 'Botol PET');

    expect(find.byType(TambahJenisSampahBottomSheet), findsNothing);
    expect(find.text('Edit Jenis Sampah'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Botol PET'), findsOneWidget);
  });

  testWidgets('the panel close button clears the form', (tester) async {
    await openPage(tester, size: _expanded);
    await editJenis(tester, 'Botol PET');

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(
      find.byType(JenisSampahForm),
      findsNothing,
      reason: 'a panel is not on a route, so it cannot be dismissed by a pop',
    );
    expect(find.text('Botol PET'), findsOneWidget);
  });

  testWidgets('selecting another row refills the open panel', (tester) async {
    await openPage(tester, size: _expanded);
    await editJenis(tester, 'Botol PET');
    expect(find.widgetWithText(TextFormField, 'Botol PET'), findsOneWidget);

    await editJenis(tester, 'Kardus');

    expect(find.widgetWithText(TextFormField, 'Kardus'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Botol PET'),
      findsNothing,
      reason: 'the previous row must not be left in any field',
    );
  });

  // A panel outlives the selection it was opened for, so a request sent for
  // one row can come back while another row is on screen. Raised by Scallss'
  // review of this PR: the result used to close the panel it found, taking
  // the next row's unsaved edits with it.
  testWidgets('a save that lands after the row changed leaves the panel alone',
      (tester) async {
    api.on('PUT', '/api/v1/jenis-sampah/1', json: {});
    await openPage(tester, size: _expanded);
    await editJenis(tester, 'Botol PET');

    // Slow enough that the row can be switched while the PUT is still out.
    api.latency = const Duration(seconds: 4);
    await tester.ensureVisible(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pump();

    // Single frames, not pumpAndSettle: settling would run the clock past the
    // success toast's three seconds, and the toast is part of what is asserted.
    // Kardus opens its detail first; Edit then swaps the panel.
    // The spinner keeps frames coming, so these are bounded pumps.
    await tester.tap(find.text('Kardus'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Edit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(find.byType(TextFormField).at(1), 'Kardus Tebal');
    await tester.pump();

    // Botol PET's answer arrives here, with Kardus on screen.
    await tester.pump(const Duration(seconds: 4));
    await pumpToast(tester);

    expect(
      find.byType(JenisSampahForm),
      findsOneWidget,
      reason: "Botol PET's save must not close the panel showing Kardus",
    );
    expect(
      find.widgetWithText(TextFormField, 'Kardus Tebal'),
      findsOneWidget,
      reason: 'the edit in progress on Kardus must survive',
    );
    expect(api.requests.where((r) => r.method == 'PUT'), isNotEmpty,
        reason: 'the save this test is about has to have been sent');
    expect(find.text('Jenis sampah berhasil diperbarui.'), findsOneWidget,
        reason: 'the save did succeed, so it is still reported');
    await settleToasts(tester);
  });

  testWidgets('a status change that lands after the row changed is contained',
      (tester) async {
    api.on('PATCH', '/api/v1/jenis-sampah/1/status', json: {});
    await openPage(tester, size: _expanded);
    await editJenis(tester, 'Botol PET');

    await tester.ensureVisible(find.text('Nonaktifkan Jenis Sampah'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nonaktifkan Jenis Sampah'));
    await tester.pumpAndSettle();
    // Far longer than the dialog's own exit, so the ordering under test is not
    // left to how long a settle happens to run for.
    api.latency = const Duration(seconds: 5);
    await tester.tap(find.text('Ya, Nonaktifkan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Kardus opens its detail first; Edit then swaps the panel.
    await tester.tap(find.text('Kardus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), 'Kardus Tebal');
    await tester.pump();

    // Botol PET's answer arrives here, with Kardus on screen. A panel that
    // closed and was reopened would look the same, so the assertion is the
    // unsaved text rather than the panel's presence alone.
    await tester.pump(const Duration(seconds: 5));
    await pumpToast(tester);

    expect(
      find.byType(JenisSampahForm),
      findsOneWidget,
      reason: 'the same rule applies to the status toggle',
    );
    expect(
      find.widgetWithText(TextFormField, 'Kardus Tebal'),
      findsOneWidget,
      reason: "Botol PET's status change must not discard Kardus' edit",
    );
    expect(api.requests.where((r) => r.method == 'PATCH'), isNotEmpty,
        reason: 'the status change this test is about has to have been sent');
    await settleToasts(tester);
  });

  testWidgets('no panel is rendered until something is selected',
      (tester) async {
    await openPage(tester, size: _expanded);
    expect(find.byType(JenisSampahForm), findsNothing);
  });

  testWidgets('a wide screen lists jenis sampah in a table', (tester) async {
    await openPage(tester, size: _expanded);

    expect(find.byType(HargaTable), findsOneWidget);
    expect(find.byType(AppTappableCard), findsNothing);
    expect(find.text('Botol PET'), findsOneWidget);
  });

  testWidgets('a medium screen also gets the table', (tester) async {
    await openPage(tester);

    expect(find.byType(HargaTable), findsOneWidget);
  });

  testWidgets('a phone keeps the cards', (tester) async {
    await openPage(tester, size: const Size(420, 1400));

    expect(find.byType(HargaTable), findsNothing);
    expect(find.byType(AppTappableCard), findsWidgets);
    expect(
        find.byType(WebPaginationBar), kIsWeb ? findsOneWidget : findsNothing);
  });

  testWidgets('tapping a table row opens its detail', (tester) async {
    await openPage(tester, size: _expanded);

    await tester.tap(find.text('Botol PET'));
    await tester.pumpAndSettle();

    expect(find.byType(HargaDetailSheet), findsOneWidget);
  });

  testWidgets('the row being edited stays tinted in the table', (tester) async {
    await openPage(tester, size: _expanded);
    await editJenis(tester, 'Botol PET');

    final row = tester.widget<Container>(find.byKey(HargaTable.rowKey('1')));
    expect(row.color, AppColors.greenLight);
  });

  testWidgets('on a wide screen the add button is in the header, not a FAB',
      (tester) async {
    await openPage(tester, size: _expanded);

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Tambah Jenis Sampah'), findsOneWidget);

    await editJenis(tester, 'Botol PET');
    expect(find.text('Tambah Jenis Sampah'), findsOneWidget,
        reason: 'nothing floats over the panel any more, so it can stay');
  });

  if (!kIsWeb) {
    testWidgets('on a phone the add button is always there', (tester) async {
      await openPage(tester, size: const Size(420, 1400));
      expect(find.byType(FloatingActionButton), findsOneWidget);

      await editJenis(tester, 'Botol PET');

      expect(
        find.byType(FloatingActionButton),
        findsOneWidget,
        reason: 'compact opens a sheet, so there is no panel to overlap',
      );
    });

    testWidgets('on a compact screen the add button opens the form',
        (tester) async {
      await openPage(tester, size: const Size(500, 844));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(TambahJenisSampahBottomSheet), findsOneWidget);
    });
  }

  // The container is chosen when the form opens, but the window can be resized
  // afterwards. Raised by TrayMachi's review of the same pattern on PR #113.
  testWidgets('shrinking below expanded closes the open panel', (tester) async {
    await openPage(tester, size: _expanded);
    await editJenis(tester, 'Botol PET');
    expect(find.byType(JenisSampahForm), findsOneWidget);

    tester.view.physicalSize = _medium;
    await tester.pumpAndSettle();

    expect(
      find.byType(JenisSampahForm),
      findsNothing,
      reason: 'a 2/5 panel at medium is the width the open path refuses',
    );
    expect(find.text('Botol PET'), findsOneWidget);
  });

  testWidgets('widening back does not resurrect a closed panel',
      (tester) async {
    await openPage(tester, size: _expanded);
    await editJenis(tester, 'Botol PET');

    tester.view.physicalSize = _medium;
    await tester.pumpAndSettle();
    tester.view.physicalSize = _expanded;
    await tester.pumpAndSettle();

    expect(
      find.byType(JenisSampahForm),
      findsNothing,
      reason: 'a blank form reappearing on resize reads as a bug',
    );
  });
}
