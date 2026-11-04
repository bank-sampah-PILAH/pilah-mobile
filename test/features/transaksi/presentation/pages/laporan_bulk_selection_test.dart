import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/aktivitas_selection_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_selection_bar.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_table.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_aktivitas_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/laporan/laporan_page.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/riwayat_aktivitas_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/states/riwayat_aktivitas_state.dart';

import '../../../../support/stub_api.dart';
import '../../../../support/transaksi_support.dart';

class _GetAktivitas extends Mock implements GetAktivitasUseCase {}

class _Export extends Mock implements ExportTransaksiUseCase {}

class _Feed extends RiwayatAktivitasNotifier {
  _Feed(this.items) : super(_GetAktivitas(), _Export());

  final List<ActivitasEntity> items;

  @override
  RiwayatAktivitasState build() => RiwayatAktivitasState(
        status: AktivitasStatus.loaded,
        items: items,
        totalCount: items.length,
      );

  @override
  Future<void> load({bool silent = false, int? pageSize}) async {}

  void changeSearch() => state = state.copyWith(search: 'Budi');

  void changePage() => state = state.copyWith(currentPage: 2);

  void markFirstVoided() => state = state.copyWith(items: [
        _setoran('s1', 'Budi', voided: true),
        ...items.skip(1),
      ]);
}

ActivitasEntity _setoran(String id, String name, {bool voided = false}) =>
    ActivitasEntity.fromTransaksi(TransaksiEntity(
      id: id,
      initials: 'BU',
      avatarColor: AppColors.greenLight,
      textColor: AppColors.greenDark,
      name: name,
      subtitle: 'PET 2 kg',
      amount: '+Rp 6.000',
      isWaSuccess: false,
      time: '10:00',
      balance: '',
      items: const [],
      tanggal: DateTime(2026, 11, 3, 10),
      isDibatalkan: voided,
    ));

ActivitasEntity _pencairan() => ActivitasEntity.fromPencairan(Pencairan(
      id: 'p1',
      nasabahNama: 'Pencairan Ani',
      nominal: 1000,
      metode: MetodePencairan.tunai,
      tanggal: DateTime(2026, 11, 3, 10),
      keterangan: '',
      status: 'tercatat',
      saldoSebelum: 6000,
      saldoSesudah: 5000,
    ));

void main() {
  late StubApi api;
  late _Feed feed;

  Future<void> pumpPage(WidgetTester tester, double width,
      {double textScale = 1,
      bool onlyVoided = false,
      bool isWeb = true}) async {
    tester.view.physicalSize = Size(width, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    api = StubApi();
    feed = _Feed(onlyVoided
        ? [_setoran('s3', 'Sudah batal', voided: true)]
        : [
            _setoran('s1', 'Budi'),
            _setoran('s2', 'Sari'),
            _setoran('s3', 'Sudah batal', voided: true),
            _pencairan(),
          ]);
    await tester.pumpWidget(withTransaksiProviders(
      transaksi: buildTransaksiNotifier(api),
      riwayat: feed,
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: LaporanPage(isWeb: isWeb),
      ),
    ));
    await tester.pumpAndSettle();
  }

  void selectBudi(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(LaporanPage)))
          .read(aktivitasSelectionProvider.notifier)
          .select('s1');

  Future<void> hold(WidgetTester tester, String name) async {
    final gesture =
        await tester.startGesture(tester.getCenter(find.text(name)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.up();
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String name) async {
    await tester.tap(find.text(name).first);
    await tester.pumpAndSettle();
  }

  Set<String>? selection(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(LaporanPage)))
          .read(aktivitasSelectionProvider);

  for (final isWeb in [true, false]) {
    group('phone, web=$isWeb', () {
      testWidgets('there is no Opsi menu and no checkbox before selecting',
          (tester) async {
        await pumpPage(tester, 390, isWeb: isWeb);

        expect(find.text('Opsi'), findsNothing);
        expect(find.byType(Checkbox), findsNothing);
        expect(find.textContaining('dipilih'), findsNothing);
      });

      testWidgets('holding a row selects it; tapping others adds them',
          (tester) async {
        await pumpPage(tester, 390, isWeb: isWeb);

        await hold(tester, 'Budi');
        expect(find.text('1 dipilih'), findsOneWidget);
        expect(find.byKey(AktivitasSelectionBar.editKey), findsOneWidget);

        await tapText(tester, 'Sari');
        expect(find.text('2 dipilih'), findsOneWidget);
        expect(selection(tester), {'s1', 's2'});
        expect(find.byKey(AktivitasSelectionBar.editKey), findsNothing);
        expect(find.widgetWithText(AppButton, 'Hapus (2)'), findsOneWidget);
        expect(find.byType(Checkbox), findsNothing);
        expect(api.requests, isEmpty,
            reason: 'selecting must not load details or void anything');
      });

      testWidgets('the bar is the green header with close before the count',
          (tester) async {
        await pumpPage(tester, 390, isWeb: isWeb);
        await hold(tester, 'Budi');
        await tapText(tester, 'Sari');

        final surface = tester.widget<Material>(find
            .descendant(
                of: find.byType(AktivitasSelectionBar),
                matching: find.byType(Material))
            .first);
        expect(surface.color, AppColors.greenDark);
        expect(tester.getTopLeft(find.byKey(AktivitasSelectionBar.closeKey)).dx,
            lessThan(tester.getTopLeft(find.text('2 dipilih')).dx));
      });

      testWidgets('deselecting back to one brings Edit back; the last exits',
          (tester) async {
        await pumpPage(tester, 390, isWeb: isWeb);
        await hold(tester, 'Budi');
        await tapText(tester, 'Sari');

        await tapText(tester, 'Sari');
        expect(find.text('1 dipilih'), findsOneWidget);
        expect(find.byKey(AktivitasSelectionBar.editKey), findsOneWidget);

        await tapText(tester, 'Budi');
        expect(selection(tester), isNull);
        expect(find.textContaining('dipilih'), findsNothing);
      });

      testWidgets('voided setoran and pencairan cannot join', (tester) async {
        await pumpPage(tester, 390, isWeb: isWeb);
        await hold(tester, 'Budi');
        await tapText(tester, 'Sudah batal');
        await tapText(tester, 'Pencairan Ani');

        expect(find.text('1 dipilih'), findsOneWidget);
        expect(selection(tester), {'s1'});
        expect(api.requests, isEmpty);
      });

      testWidgets('Hapus with one selected is the single void; with two, bulk',
          (tester) async {
        await pumpPage(tester, 390, isWeb: isWeb);
        await hold(tester, 'Budi');
        await tester.tap(find.byKey(AktivitasSelectionBar.hapusKey));
        await tester.pumpAndSettle();
        expect(find.text('Hapus Setoran?'), findsOneWidget);
        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();

        await tapText(tester, 'Sari');
        await tester.tap(find.widgetWithText(AppButton, 'Hapus (2)'));
        await tester.pumpAndSettle();
        expect(find.text('Hapus 2 setoran?'), findsOneWidget);
      });
    });
  }

  group('wide table', () {
    testWidgets('checkboxes are visible with no menu step', (tester) async {
      await pumpPage(tester, 1200);

      expect(find.text('Opsi'), findsNothing);
      // Two selectable setoran plus the select-all box in the header.
      expect(find.byType(Checkbox), findsNWidgets(3));
      expect(find.textContaining('dipilih'), findsNothing);
      expect(find.text('Edit'), findsWidgets);
    });

    testWidgets('checking a row shows the bar and hides the row buttons',
        (tester) async {
      await pumpPage(tester, 1200);

      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pumpAndSettle();

      expect(find.text('1 dipilih'), findsOneWidget);
      expect(selection(tester), {'s1'});
      expect(find.text('Edit'), findsNothing);
      expect(api.requests, isEmpty);
    });

    testWidgets('the header checkbox selects every eligible row, then clears',
        (tester) async {
      await pumpPage(tester, 1200);

      await tester.tap(find.byKey(AktivitasTable.selectAllKey));
      await tester.pumpAndSettle();
      expect(find.text('2 dipilih'), findsOneWidget);
      expect(selection(tester), {'s1', 's2'});
      expect(
          tester
              .widget<Checkbox>(find.byKey(AktivitasTable.selectAllKey))
              .value,
          isTrue);

      await tester.tap(find.byKey(AktivitasTable.selectAllKey));
      await tester.pumpAndSettle();
      expect(selection(tester), isNull);
      expect(find.text('Edit'), findsWidgets);
    });

    testWidgets('the header checkbox is mixed while only some are checked',
        (tester) async {
      await pumpPage(tester, 1200);
      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pumpAndSettle();

      final box =
          tester.widget<Checkbox>(find.byKey(AktivitasTable.selectAllKey));
      expect(box.tristate, isTrue);
      expect(box.value, isNull);
    });

    testWidgets('tapping a row expands it until something is selected',
        (tester) async {
      await pumpPage(tester, 1200);

      await tapText(tester, 'Budi');
      expect(selection(tester), isNull);
      expect(api.requests, isNotEmpty,
          reason: 'expanding a row loads its detail; selecting never does');
    });

    testWidgets('no selectable setoran: nothing to select all', (tester) async {
      await pumpPage(tester, 1200, onlyVoided: true);

      final box =
          tester.widget<Checkbox>(find.byKey(AktivitasTable.selectAllKey));
      expect(box.onChanged, isNull);
    });
  });

  for (final width in [390.0, 1200.0]) {
    testWidgets('changing search or page exits selection at $width',
        (tester) async {
      await pumpPage(tester, width);
      selectBudi(tester);
      await tester.pumpAndSettle();
      expect(selection(tester), {'s1'});
      feed.changeSearch();
      await tester.pumpAndSettle();
      expect(selection(tester), isNull);

      selectBudi(tester);
      await tester.pumpAndSettle();
      feed.changePage();
      await tester.pumpAndSettle();
      expect(selection(tester), isNull);
    });

    testWidgets(
        'refresh removes a selection that another pengurus voided at $width',
        (tester) async {
      await pumpPage(tester, width);
      selectBudi(tester);
      await tester.pumpAndSettle();
      feed.markFirstVoided();
      await tester.pumpAndSettle();
      expect(selection(tester), isNull);
      expect(find.textContaining('dipilih'), findsNothing);
    });
  }

  testWidgets('selection controls fit a narrow phone with large text',
      (tester) async {
    await pumpPage(tester, 320, textScale: 2);
    selectBudi(tester);
    await tester.pumpAndSettle();
    expect(find.text('1 dipilih'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
