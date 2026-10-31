import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/design/widgets/app_dialog.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_aktivitas_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/aktivitas_selection_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/riwayat_aktivitas_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/states/riwayat_aktivitas_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_list_view.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_selection_bar.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/batalkan_setoran_dialog.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/edit_setoran_sheet.dart';

import '../../../../support/stub_api.dart';
import '../../../../support/transaksi_support.dart';

const _batalkan = '/api/v1/transaksi/t1/batalkan';

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

ActivitasEntity _setoran(String id, String name, {bool dibatalkan = false}) =>
    ActivitasEntity.fromTransaksi(TransaksiEntity(
      id: id,
      initials: 'BU',
      avatarColor: Colors.green.shade100,
      textColor: Colors.green,
      name: name,
      subtitle: 'Botol PET • 2 kg',
      amount: '+Rp 6.000',
      isWaSuccess: false,
      time: '10:00',
      balance: '',
      items: const [],
      tanggal: DateTime(2026, 10, 5, 10),
      isDibatalkan: dibatalkan,
    ));

Map<String, dynamic> _dibatalkan() => {
      'nasabah_nama': 'Budi',
      'tanggal': '2026-10-05T03:00:00Z',
      'total_nilai': '6000.00',
      'saldo_setelah_transaksi': '0',
      'status_wa': 'terkirim',
      'items': [],
      'status': 'dibatalkan',
      'alasan_batal': 'Dobel',
      'dibatalkan_oleh_nama': 'Pengelola',
      'dibatalkan_pada': '2026-10-06T02:30:00Z',
    };

void main() {
  late StubApi api;
  late _Feed feed;

  setUp(() => api = StubApi());

  group('Hapus from the phone selection header', () {
    Future<ProviderContainer> pumpFeed(WidgetTester tester,
        {List<ActivitasEntity>? items}) async {
      feed = _Feed(RiwayatAktivitasState(
        status: AktivitasStatus.loaded,
        items: items ?? [_setoran('t1', 'Budi'), _setoran('t2', 'Sari')],
        totalCount: 2,
      ));
      late ProviderContainer container;
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(withTransaksiProviders(
        transaksi: buildTransaksiNotifier(api),
        riwayat: feed,
        child: MaterialApp(
          home: Consumer(builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            final selecting = ref.watch(aktivitasSelectionProvider) != null;
            return Scaffold(
              body: Column(children: [
                if (selecting)
                  AktivitasSelectionBar(
                    onEdit: (id) => showEditSetoranSheet(context, id),
                    onHapus: (id) => showBatalkanSetoranDialog(context, id),
                  ),
                const Expanded(child: AktivitasListView(isWeb: false)),
              ]),
            );
          }),
        ),
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

    Finder confirm() => find.descendant(
        of: find.byType(AppDialog),
        matching: find.widgetWithText(AppButton, 'Hapus'));

    Future<void> openHapus(WidgetTester tester) async {
      await hold(tester, 'Budi');
      await tester.tap(find.byKey(AktivitasSelectionBar.hapusKey));
      await tester.pumpAndSettle();
    }

    testWidgets('the dialog says what a void does before anything is sent',
        (tester) async {
      await pumpFeed(tester);

      await openHapus(tester);

      expect(find.text('Hapus Setoran?'), findsOneWidget);
      expect(find.textContaining('label "Dibatalkan"'), findsOneWidget);
      expect(find.textContaining('tidak lagi dihitung'), findsOneWidget);
      expect(api.requests, isEmpty);
    });

    testWidgets('Hapus without an alasan is refused on the spot',
        (tester) async {
      await pumpFeed(tester);
      await openHapus(tester);

      await tester.tap(confirm());
      await tester.pumpAndSettle();

      expect(find.text('Alasan pembatalan wajib diisi'), findsOneWidget);
      expect(api.requests, isEmpty);
    });

    testWidgets('a void with an alasan closes, clears and reloads the feed',
        (tester) async {
      api.on('POST', _batalkan, json: _dibatalkan());
      final container = await pumpFeed(tester);
      await openHapus(tester);

      await tester.enterText(
          find.byKey(BatalkanSetoranDialog.alasanKey), 'Dobel');
      await tester.tap(confirm());
      await tester.pumpAndSettle();

      expect(api.last.path, _batalkan);
      expect(api.last.json, {'alasan': 'Dobel'});
      expect(find.text('Hapus Setoran?'), findsNothing);
      expect(container.read(aktivitasSelectionProvider), isNull);
      expect(feed.loads, 1);
    });

    testWidgets('a refused void keeps the dialog open with the reason',
        (tester) async {
      const pesan =
          'Setoran ini tidak bisa dibatalkan karena sebagian saldonya sudah dicairkan';
      api.on('POST', _batalkan, status: 409, json: {'error': pesan});
      await pumpFeed(tester);
      await openHapus(tester);

      await tester.enterText(
          find.byKey(BatalkanSetoranDialog.alasanKey), 'Dobel');
      await tester.tap(confirm());
      await tester.pumpAndSettle();

      expect(find.text(pesan), findsOneWidget);
      expect(find.text('Hapus Setoran?'), findsOneWidget);
      expect(feed.loads, 0);
    });

    testWidgets('Batal closes the dialog and sends nothing', (tester) async {
      final container = await pumpFeed(tester);
      await openHapus(tester);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.text('Hapus Setoran?'), findsNothing);
      expect(api.requests, isEmpty);
      expect(container.read(aktivitasSelectionProvider), 't1');
    });

    testWidgets('a voided row cannot be selected', (tester) async {
      await pumpFeed(tester, items: [
        _setoran('t1', 'Budi', dibatalkan: true),
        _setoran('t2', 'Sari'),
      ]);

      expect(find.text('Dibatalkan'), findsOneWidget);

      await hold(tester, 'Budi');
      // Released, the hold is a plain tap: the row opens its detail instead.
      await tester.pumpAndSettle();

      expect(find.text('1 dipilih'), findsNothing);
      expect(find.byKey(AktivitasSelectionBar.hapusKey), findsNothing);
    });
  });

  group('Aksi column on a wide screen', () {
    Future<void> pumpTable(
        WidgetTester tester, List<ActivitasEntity> items) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      feed = _Feed(RiwayatAktivitasState(
        status: AktivitasStatus.loaded,
        items: items,
        totalCount: items.length,
      ));
      await tester.pumpWidget(withTransaksiProviders(
        transaksi: buildTransaksiNotifier(api),
        riwayat: feed,
        child: const MaterialApp(
          home: Scaffold(body: AktivitasListView(isWeb: true)),
        ),
      ));
      await tester.pump();
    }

    testWidgets('a setoran row has a Hapus button that asks for an alasan',
        (tester) async {
      await pumpTable(tester, [_setoran('t1', 'Budi')]);

      final button = find.byKey(const ValueKey('aktivitas-hapus'));
      expect(tester.widget(button), isA<AppButton>());
      expect(find.descendant(of: button, matching: find.text('Hapus')),
          findsOneWidget);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('Hapus Setoran?'), findsOneWidget);
      expect(find.byKey(BatalkanSetoranDialog.alasanKey), findsOneWidget);
    });

    testWidgets('the dialog stays narrow on a wide screen', (tester) async {
      await pumpTable(tester, [_setoran('t1', 'Budi')]);

      await tester.tap(find.byKey(const ValueKey('aktivitas-hapus')));
      await tester.pumpAndSettle();

      // The dialog's card, not the full-screen box around it.
      final card = find
          .descendant(
              of: find.byType(AlertDialog), matching: find.byType(Material))
          .first;
      expect(tester.getSize(card).width, lessThanOrEqualTo(520));
    });

    testWidgets('a voided row is labelled and offers no action',
        (tester) async {
      await pumpTable(tester, [_setoran('t1', 'Budi', dibatalkan: true)]);

      expect(find.text('Dibatalkan'), findsOneWidget);
      expect(find.byKey(const ValueKey('aktivitas-edit')), findsNothing);
      expect(find.byKey(const ValueKey('aktivitas-hapus')), findsNothing);
    });
  });
}
