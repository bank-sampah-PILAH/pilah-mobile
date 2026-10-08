import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/recent_activity_cubit.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_cubit.dart';
import 'package:pilah_mobile/features/transaksi/data/datasources/transaksi_remote_data_source_impl.dart';
import 'package:pilah_mobile/features/transaksi/data/repositories/transaksi_repository_impl.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/transaksi_baru_page.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/item_setoran_card.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/transaksi_berhasil_bottom_sheet.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../../../support/dashboard_support.dart';
import '../../../../support/harga_support.dart';
import '../../../../support/nasabah_support.dart';
import '../../../../support/pencairan_support.dart';
import '../../../../support/profile_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';
import '../../../../support/transaksi_support.dart';

class _MockUrlLauncher extends Mock
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {}

class _FakeLaunchOptions extends Fake implements LaunchOptions {}

Map<String, dynamic> _jenis(String id, String nama, String harga,
        {String kategori = 'plastik', bool active = true}) =>
    {
      'id': id,
      'kode': 'K-$id',
      'nama_sampah': nama,
      'kategori': kategori,
      'deskripsi': '',
      'harga_per_kg': harga,
      'is_active': active,
    };

void main() {
  late StubApi api;
  late _MockUrlLauncher launcher;

  setUpAll(() {
    registerFallbackValue(_FakeLaunchOptions());
    registerFallbackValue(PreferredLaunchMode.externalApplication);
  });

  setUp(() {
    api = StubApi();
    launcher = _MockUrlLauncher();
    UrlLauncherPlatform.instance = launcher;
    when(() => launcher.supportsMode(any())).thenAnswer((_) async => true);
    when(() => launcher.supportsCloseForMode(any()))
        .thenAnswer((_) async => false);
    when(() => launcher.launchUrl(any(), any())).thenAnswer((_) async => true);

    api.on('GET', '/api/v1/jenis-sampah', json: {
      'results': [
        _jenis('j1', 'Botol PET', '2000'),
        _jenis('j2', 'Kardus', '1000', kategori: 'kertas'),
      ],
    });
    stubProfile(api);
    api.on('GET', '/api/v1/nasabah',
        json: nasabahPage([
          nasabahRow('n1', nama: 'Budi Santoso'),
        ]));
    api.on('GET', '/api/v1/transaksi', json: {'results': []});
    api.on('GET', '/api/v1/pencairan', json: {'results': [], 'next': null});
    api.on('GET', '/api/v1/dashboard/stats', json: <String, dynamic>{});
  });

  /// Opens the real page with the real cubits it reads, over the stubbed API.
  Future<void> open(WidgetTester tester,
      {Size window = const Size(800, 2600)}) async {
    final harga = buildHargaCubit(api);
    final profile = buildProfileCubit(api);
    final transaksi = buildTransaksiCubit(api);
    final dashboard = buildDashboardCubit(api);
    final pencairan = buildPencairanUseCases(api);
    final getTransaksi = GetTransaksiUseCase(
        TransaksiRepositoryImpl(TransaksiRemoteDataSourceImpl(api.network)));
    final export = ExportTransaksiUseCase(
        TransaksiRepositoryImpl(TransaksiRemoteDataSourceImpl(api.network)));
    final recent = RecentActivityCubit(getTransaksi, pencairan);
    final riwayat = RiwayatAktivitasCubit(getTransaksi, pencairan, export);
    final nasabah = buildNasabahCubit(api);
    addTearDown(() async {
      await harga.close();
      await profile.close();
      await transaksi.close();
      await dashboard.close();
      await recent.close();
      await riwayat.close();
      await nasabah.close();
    });

    await pumpRouted(
      tester,
      // A non-const instance so the constructor itself runs.
      // ignore: prefer_const_constructors
      TransaksiBaruPage(),
      wrap: (app) => MultiBlocProvider(
        providers: [
          BlocProvider<HargaCubit>.value(value: harga),
          BlocProvider<ProfileCubit>.value(value: profile),
          BlocProvider<TransaksiCubit>.value(value: transaksi),
          BlocProvider<DashboardCubit>.value(value: dashboard),
          BlocProvider<RecentActivityCubit>.value(value: recent),
          BlocProvider<RiwayatAktivitasCubit>.value(value: riwayat),
          BlocProvider<NasabahCubit>.value(value: nasabah),
        ],
        child: app,
      ),
      pushed: true,
      size: window,
    );
    await tester.pumpAndSettle();
  }

  Future<void> pickNasabah(WidgetTester tester) async {
    await tester.tap(find.text('Tap untuk pilih nasabah'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Budi Santoso'));
    await tester.pumpAndSettle();
  }

  Future<void> addItem(WidgetTester tester, String jenis,
      {int index = 0}) async {
    await tester.ensureVisible(find.text('Tambah Item Setoran'));
    await tester.tap(find.text('Tambah Item Setoran'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih Jenis').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(jenis).last);
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Simpan Transaksi'));
    await tester.tap(find.text('Simpan Transaksi'));
    await pumpToast(tester);
  }

  testWidgets('loads the price list and the WhatsApp template on open',
      (tester) async {
    await open(tester);

    expect(api.requests.any((r) => r.path == '/api/v1/jenis-sampah'), isTrue);
    expect(api.requests.any((r) => r.path == '/api/v1/pengaturan/wa-template'),
        isTrue);
    expect(find.text('Transaksi Baru'), findsOneWidget);
    expect(find.text('Belum Ada Item Setoran'), findsOneWidget);
    expect(find.text('0 item'), findsOneWidget);
  });

  testWidgets('submitting an empty form flags the customer and the items',
      (tester) async {
    await open(tester);

    await save(tester);

    expect(find.text('Nasabah harus dipilih'), findsOneWidget);
    expect(find.text('Daftar setoran tidak boleh kosong'), findsOneWidget);
    expect(api.requests.where((r) => r.method == 'POST'), isEmpty);
    await settleToasts(tester);
  });

  group('the form on a wide window', () {
    testWidgets('the summary and save sit beside the fields, not below',
        (tester) async {
      await open(tester, window: const Size(1440, 1200));
      await pickNasabah(tester);
      await addItem(tester, 'Botol PET');

      final card = tester.getRect(find.byType(ItemSetoranCard));
      final save = tester.getRect(find.text('Simpan Transaksi'));

      expect(save.left, greaterThanOrEqualTo(card.right),
          reason: 'a 1440px window has room for two columns; stacking the '
              'summary below the fields wastes all of it');
    });

    testWidgets('the content is bounded rather than stretched edge to edge',
        (tester) async {
      await open(tester, window: const Size(1440, 1200));
      await pickNasabah(tester);
      await addItem(tester, 'Botol PET');

      final card = tester.getRect(find.byType(ItemSetoranCard));
      expect(card.left, greaterThan(100),
          reason: 'content capped at 1200 and centred leaves a gutter; '
              'full-bleed fields would start at the page padding');
    });

    testWidgets('a phone still stacks the save button below the fields',
        (tester) async {
      await open(tester, window: const Size(390, 2600));
      await pickNasabah(tester);
      await addItem(tester, 'Botol PET');

      final card = tester.getRect(find.byType(ItemSetoranCard));
      final save = tester.getRect(find.text('Simpan Transaksi'));

      expect(save.top, greaterThan(card.bottom),
          reason: 'the phone layout must not change');
    });
  });

  /// The weight box is the last text field in the card; the price field above
  /// it is read-only.
  Future<void> setBerat(WidgetTester tester, String value) async {
    final berat = find
        .descendant(
            of: find.byType(ItemSetoranCard),
            matching: find.byType(TextFormField))
        .last;
    await tester.enterText(berat, value);
    await tester.pumpAndSettle();
  }

  testWidgets('an item left at zero weight is flagged, not posted',
      (tester) async {
    await open(tester);
    await pickNasabah(tester);
    await addItem(tester, 'Botol PET');
    await setBerat(tester, '0');

    await save(tester);

    expect(api.requests.where((r) => r.method == 'POST'), isEmpty,
        reason: 'a 0 kg setoran must not be sent at all');
    expect(find.text('Berat harus lebih dari 0'), findsOneWidget,
        reason: 'the backend rejects it (PIL-224), so the form should say so '
            'before the round trip rather than after it');
    await settleToasts(tester);
  });

  testWidgets('an item with no jenis chosen is flagged', (tester) async {
    await open(tester);
    await pickNasabah(tester);
    await tester.tap(find.text('Tambah Item Setoran'));
    await tester.pumpAndSettle();

    await save(tester);

    expect(find.text('Pilih jenis sampah'), findsOneWidget);
    expect(api.requests.where((r) => r.method == 'POST'), isEmpty);
    await settleToasts(tester);
  });

  testWidgets('picking a customer and a jenis fills in price and totals',
      (tester) async {
    await open(tester);
    await pickNasabah(tester);
    expect(find.text('NAS-n1'), findsOneWidget);

    await addItem(tester, 'Botol PET');

    expect(find.text('1 item'), findsOneWidget);
    expect(find.text('Rp 2.000'), findsWidgets);

    await tester.enterText(find.byType(TextFormField).last, '2,5');
    await tester.pump();
    expect(find.text('Rp 5.000'), findsWidgets);
  });

  testWidgets('the same jenis cannot be added twice', (tester) async {
    await open(tester);
    await addItem(tester, 'Botol PET');

    await tester.ensureVisible(find.text('Tambah Item Setoran'));
    await tester.tap(find.text('Tambah Item Setoran'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih Jenis').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Botol PET').last);
    await pumpToast(tester);

    expect(find.text('Jenis Sudah Dipilih'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('an item can be removed again', (tester) async {
    await open(tester);
    await addItem(tester, 'Kardus');

    await tester.tap(find.byIcon(Icons.close).first);
    await pumpToast(tester);

    expect(find.text('Item setoran berhasil dihapus.'), findsOneWidget);
    expect(find.text('0 item'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('a rejected save shows the message and keeps the form',
      (tester) async {
    api.on('POST', '/api/v1/transaksi', status: 422, json: {
      'errors': {
        'items': ['Berat harus positif']
      }
    });
    await open(tester);
    await pickNasabah(tester);
    await addItem(tester, 'Botol PET');

    await save(tester);

    expect(find.text('Berat harus positif'), findsOneWidget);
    expect(find.text('Simpan Transaksi'), findsOneWidget);
    await settleToasts(tester);

    // A retry reuses the same idempotency key.
    await save(tester);
    final keys = api.requests
        .where((r) => r.method == 'POST')
        .map((r) => r.headers['Idempotency-Key'])
        .toSet();
    expect(keys, hasLength(1));
    await settleToasts(tester);
  });

  testWidgets('a saved transaksi opens the success sheet and WhatsApp draft',
      (tester) async {
    api.on('POST', '/api/v1/transaksi', status: 201, json: {
      'id': 't1',
      'total_nilai': '5000',
      'saldo_setelah_transaksi': '30000',
      'items': [{}],
    });
    await open(tester);
    await pickNasabah(tester);
    await addItem(tester, 'Botol PET');
    await tester.enterText(find.byType(TextFormField).last, '2,5');
    await tester.pump();

    await save(tester);

    expect(find.byType(TransaksiBerhasilBottomSheet), findsOneWidget);
    expect(find.text('Transaksi Berhasil!'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsWidgets);
    expect(find.text('+Rp 5.000'), findsOneWidget);
    expect(find.text('Rp 30.000'), findsOneWidget);
    // The shell tabs that stay alive were nudged to refresh.
    expect(
        api.requests.any((r) => r.path == '/api/v1/dashboard/stats'), isTrue);

    await tester.tap(find.text('Kirim Notif WhatsApp & Selesai'));
    await pumpToast(tester);

    final launched = verify(() => launcher.launchUrl(captureAny(), any()))
        .captured
        .single as String;
    expect(launched, startsWith('https://wa.me/'));
    expect(find.text('route:/'), findsOneWidget);
    expect(
        find.textContaining('Pesan WhatsApp sudah disiapkan'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('a WhatsApp that cannot be opened is only a warning',
      (tester) async {
    when(() => launcher.launchUrl(any(), any())).thenAnswer((_) async => false);
    api.on('POST', '/api/v1/transaksi', status: 201, json: {
      'id': 't1',
      'total_nilai': '2000',
      'saldo_setelah_transaksi': '2000',
      'items': [{}],
    });
    await open(tester);
    await pickNasabah(tester);
    await addItem(tester, 'Botol PET');
    await save(tester);

    await tester.tap(find.text('Kirim Notif WhatsApp & Selesai'));
    await pumpToast(tester);

    expect(find.textContaining('WhatsApp tidak dapat dibuka'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('a launcher that throws is handled like a failure to open',
      (tester) async {
    when(() => launcher.launchUrl(any(), any()))
        .thenAnswer((_) async => throw PlatformException(code: 'x'));
    api.on('POST', '/api/v1/transaksi', status: 201, json: {
      'id': 't1',
      'total_nilai': '2000',
      'saldo_setelah_transaksi': '2000',
      'items': [{}],
    });
    await open(tester);
    await pickNasabah(tester);
    await addItem(tester, 'Botol PET');
    await save(tester);

    await tester.tap(find.text('Kirim Notif WhatsApp & Selesai'));
    await pumpToast(tester);

    expect(find.textContaining('WhatsApp tidak dapat dibuka'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('the back button leaves the page', (tester) async {
    await open(tester);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('route:/'), findsOneWidget);
  });
}
