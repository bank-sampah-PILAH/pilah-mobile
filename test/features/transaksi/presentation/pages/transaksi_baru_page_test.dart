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
import 'package:pilah_mobile/features/transaksi/presentation/widgets/pilih_nasabah_section.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/transaksi_berhasil_panel.dart';
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

  /// Flagging only after the save button is pressed means the pengelola can
  /// clear a weight box, look away, and learn about it a minute later. A zero
  /// weight is worth saying at once, because — unlike a missing jenis — it is
  /// unreachable without an edit: `_addItem` starts every card at 1 kg. So the
  /// two problems get different timing, and a brand-new card stays neutral.
  ///
  /// Pressing save must also *say* something. Today an invalid form returns
  /// silently and only the inline text changes, which is easy to miss when the
  /// offending card has scrolled out of view.
  group('menandai sebelum tombol simpan ditekan', () {
    testWidgets('a freshly added card is not flagged', (tester) async {
      await open(tester);
      await pickNasabah(tester);
      await tester.ensureVisible(find.text('Tambah Item Setoran'));
      await tester.tap(find.text('Tambah Item Setoran'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih jenis sampah'), findsNothing,
          reason: 'a new card has no jenis yet; reddening it before the '
              'pengelola has done anything is nagging, not reminding');
      expect(find.text('Berat harus lebih dari 0'), findsNothing);
    });

    testWidgets('clearing the weight flags the card without pressing save',
        (tester) async {
      await open(tester);
      await pickNasabah(tester);
      await addItem(tester, 'Botol PET');
      await setBerat(tester, '0');

      expect(find.text('Berat harus lebih dari 0'), findsOneWidget,
          reason: '0 kg can only be reached by editing, so it can be flagged '
              'at once instead of waiting for the save button');
      expect(api.requests.where((r) => r.method == 'POST'), isEmpty);
    });

    testWidgets('a blocked save raises a notification', (tester) async {
      await open(tester);

      await save(tester);

      expect(find.text('Belum Bisa Disimpan'), findsOneWidget);
      await settleToasts(tester);
    });

    testWidgets('the notification names what is missing', (tester) async {
      await open(tester);
      await pickNasabah(tester);
      await tester.ensureVisible(find.text('Tambah Item Setoran'));
      await tester.tap(find.text('Tambah Item Setoran'));
      await tester.pumpAndSettle();

      await save(tester);

      expect(find.textContaining('ada item tanpa jenis sampah'), findsOneWidget,
          reason: 'wording distinct from the inline "Pilih jenis sampah", so '
              'this cannot pass by matching the card text instead');
      await settleToasts(tester);
    });

    testWidgets('the notification comes back on every blocked attempt',
        (tester) async {
      await open(tester);

      await save(tester);
      expect(find.text('Belum Bisa Disimpan'), findsOneWidget);
      await settleToasts(tester);
      expect(find.text('Belum Bisa Disimpan'), findsNothing);

      await save(tester);

      expect(find.text('Belum Bisa Disimpan'), findsOneWidget,
          reason: 'a second press must not be silent just because the first '
              'one already complained');
      await settleToasts(tester);
    });
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

    expect(find.byType(TransaksiBerhasilPanel), findsOneWidget);
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

  /// `_isSaving` only disables the save button. Every other control stays
  /// live while the POST is in flight — the nasabah picker, the weight boxes,
  /// the per-item delete.
  ///
  /// That matters because `buildWaSetoranLink` is built *after* the await, from
  /// `selectedCustomer` and `setoranItems` as they are then, while its own
  /// comment claims it is "a snapshot of what was actually submitted". Edit the
  /// form during the round trip and the WhatsApp draft describes a setoran the
  /// server never saw.
  group('the form while a save is in flight', () {
    /// Taps save and returns with the POST still unresolved. The `save` helper
    /// cannot be used here: its `pumpToast` advances 1.2s and would finish it.
    Future<void> beginSave(WidgetTester tester) async {
      api.latency = const Duration(seconds: 1);
      await tester.ensureVisible(find.text('Simpan Transaksi'));
      await tester.tap(find.text('Simpan Transaksi'));
      await tester.pump();
    }

    /// Lets the held request resolve. The clock has to be advanced explicitly:
    /// `pumpAndSettle` alone returns as soon as the tree stops animating and
    /// does not wait for a pending `Future.delayed`.
    Future<void> finishSave(WidgetTester tester) async {
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    }

    testWidgets('the WhatsApp draft describes the setoran that was saved',
        (tester) async {
      api.on('POST', '/api/v1/transaksi', json: {
        'id': 't1',
        'total_nilai': '5000',
        'saldo_setelah_transaksi': '30000',
        'items': [{}],
      });
      // The default stub template is `Halo {nama}`, which contains no item
      // placeholder at all and so could never tell the two outcomes apart.
      stubProfile(api, wa: {
        'template': 'Setoran: {daftar_item}',
        'preview_contoh': 'Setoran: -',
        'variabel_tersedia': ['{daftar_item}'],
      });
      await open(tester);
      await pickNasabah(tester);
      await addItem(tester, 'Botol PET');

      await beginSave(tester);
      // Deleting an item is pure local state, so it needs no network and lands
      // squarely inside the round trip.
      await tester.tap(find.byIcon(Icons.close).first);
      await finishSave(tester);

      await tester.tap(find.text('Kirim Notif WhatsApp & Selesai'));
      await pumpToast(tester);

      final launched = verify(() => launcher.launchUrl(captureAny(), any()))
          .captured
          .single as String;
      expect(launched, contains('Botol'),
          reason: 'the nasabah is told what was actually recorded against '
              'their balance, not what the form happened to hold afterwards');
      await settleToasts(tester);
    });

    testWidgets('the form cannot be edited while the save is in flight',
        (tester) async {
      api.on('POST', '/api/v1/transaksi', json: {
        'id': 't1',
        'total_nilai': '5000',
        'saldo_setelah_transaksi': '30000',
        'items': [{}],
      });
      await open(tester);
      await pickNasabah(tester);
      await addItem(tester, 'Botol PET');

      await beginSave(tester);
      await tester.tap(find.byType(PilihNasabahSection));
      await tester.pump();

      expect(find.byType(Dialog), findsNothing,
          reason: 'changing the nasabah mid-request would describe one '
              'setoran to a different person');
      await finishSave(tester);
      await settleToasts(tester);
    });
  });

  /// A pengelola records a setoran with one hand on a weighing scale. Reaching
  /// for the mouse between every item is the slow part, so the keyboard has to
  /// carry the whole loop: type a weight, submit, move to the next box.
  ///
  /// Two things block that today. The price box is `readOnly` but still takes
  /// focus, so Tab stops on a field that cannot be typed into. And the weight
  /// box has no submit action at all, so Enter does nothing.
  ///
  /// There is also a hole left by the in-flight freeze: `AbsorbPointer` stops
  /// pointers, not keys, so Enter can still reach a form that is mid-save.
  group('the keyboard can drive the form', () {
    Finder weightOf(int index) => find
        .descendant(
            of: find.byType(ItemSetoranCard).at(index),
            matching: find.byType(TextFormField))
        .last;

    testWidgets('Enter in the weight box saves the setoran', (tester) async {
      api.on('POST', '/api/v1/transaksi', json: {
        'id': 't1',
        'total_nilai': '5000',
        'saldo_setelah_transaksi': '30000',
        'items': [{}],
      });
      await open(tester);
      await pickNasabah(tester);
      await addItem(tester, 'Botol PET');

      await tester.enterText(weightOf(0), '2,5');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(api.requests.where((r) => r.method == 'POST').length, 1,
          reason: 'the whole loop should be typeable without the mouse');
      await settleToasts(tester);
    });

    testWidgets('Enter does nothing while a save is in flight', (tester) async {
      api.on('POST', '/api/v1/transaksi', json: {
        'id': 't1',
        'total_nilai': '5000',
        'saldo_setelah_transaksi': '30000',
        'items': [{}],
      });
      await open(tester);
      await pickNasabah(tester);
      await addItem(tester, 'Botol PET');
      await tester.enterText(weightOf(0), '2,5');
      await tester.pump();

      api.latency = const Duration(seconds: 1);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      // The freeze stops pointers, not keys, so this is the path around it.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(api.requests.where((r) => r.method == 'POST').length, 1,
          reason: 'a second Enter during the round trip must not post twice');
      await settleToasts(tester);
    });

    testWidgets('tab skips the read-only price box', (tester) async {
      await open(tester);
      await pickNasabah(tester);
      await addItem(tester, 'Botol PET');
      await addItem(tester, 'Kardus');

      await tester.tap(weightOf(0));
      await tester.pumpAndSettle();

      // Swept rather than asserted one step at a time: the delete button and
      // the jenis selector legitimately take focus between the two weight
      // boxes, so the order is not ours to pin down. What is ours is that a
      // box nobody can type into never takes a turn.
      var reachedSecondWeight = false;
      for (var step = 0; step < 14; step++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        final fields =
            tester.widgetList<EditableText>(find.byType(EditableText));
        expect(
          fields.where((field) => field.readOnly && field.focusNode.hasFocus),
          isEmpty,
          reason: 'step $step put focus on a read-only price box; Tab must '
              'never stop on a field that cannot be typed in',
        );
        if (tester
            .widget<EditableText>(find.byType(EditableText).last)
            .focusNode
            .hasFocus) {
          reachedSecondWeight = true;
        }
      }

      expect(reachedSecondWeight, isTrue,
          reason: 'the second weight box must be reachable by Tab, or the '
              'keyboard loop stops at the first item');
      await settleToasts(tester);
    });
  });

  /// The success confirmation is the last step of the flow and still arrives
  /// as a bottom sheet on every window. On a 1440px monitor that means a band
  /// across the bottom edge, far from the save button that produced it — which
  /// on a wide window lives in the right-hand summary panel.
  ///
  /// It is deliberately not dismissible: the pengelola has to choose whether to
  /// send the WhatsApp draft. Whatever container it gets must keep that.
  group('the success confirmation follows the window width', () {
    Future<void> saveSuccessfully(WidgetTester tester, Size window) async {
      api.on('POST', '/api/v1/transaksi', json: {
        'id': 't1',
        'total_nilai': '5000',
        'saldo_setelah_transaksi': '30000',
        'items': [{}],
      });
      await open(tester, window: window);
      await pickNasabah(tester);
      await addItem(tester, 'Botol PET');
      await save(tester);
    }

    testWidgets('a wide window gets a dialog', (tester) async {
      await saveSuccessfully(tester, const Size(1440, 1200));

      expect(find.text('Transaksi Berhasil!'), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget,
          reason: 'the save button is in the right-hand panel on this width; '
              'the answer should not appear at the opposite edge');
      expect(find.byType(BottomSheet), findsNothing);
      await settleToasts(tester);
    });

    testWidgets('a phone keeps the bottom sheet', (tester) async {
      await saveSuccessfully(tester, const Size(390, 2600));

      expect(find.text('Transaksi Berhasil!'), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      await settleToasts(tester);
    });

    testWidgets('it still cannot be dismissed by tapping outside',
        (tester) async {
      await saveSuccessfully(tester, const Size(1440, 1200));

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Transaksi Berhasil!'), findsOneWidget,
          reason: 'choosing whether to send the WhatsApp draft is the point of '
              'this step, so it must not be dismissable by accident');
      await settleToasts(tester);
    });

    testWidgets('the WhatsApp draft still opens from the dialog',
        (tester) async {
      await saveSuccessfully(tester, const Size(1440, 1200));

      await tester.tap(find.text('Kirim Notif WhatsApp & Selesai'));
      await pumpToast(tester);

      final launched = verify(() => launcher.launchUrl(captureAny(), any()))
          .captured
          .single as String;
      expect(launched, startsWith('https://wa.me/'));
      expect(find.text('route:/'), findsOneWidget,
          reason: 'the dialog closes and the page leaves, as the sheet did');
      await settleToasts(tester);
    });
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
