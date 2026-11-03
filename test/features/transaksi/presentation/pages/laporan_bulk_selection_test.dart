import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
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
      {double textScale = 1, bool onlyVoided = false}) async {
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
        home: const LaporanPage(isWeb: true),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> enterSelection(WidgetTester tester) async {
    await tester.tap(find.text('Opsi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih Setoran'));
    await tester.pumpAndSettle();
  }

  for (final width in [390.0, 1200.0]) {
    testWidgets('Opsi starts empty multi-selection at width $width',
        (tester) async {
      await pumpPage(tester, width);
      await enterSelection(tester);

      expect(find.text('0 dipilih'), findsOneWidget);
      expect(find.byType(Checkbox), findsNWidgets(2));
      expect(api.requests, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('two rows toggle independently at width $width',
        (tester) async {
      await pumpPage(tester, width);
      await enterSelection(tester);

      await tester.tap(find.text('Budi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sari'));
      await tester.pumpAndSettle();
      expect(find.text('2 dipilih'), findsOneWidget);
      expect(
          tester
              .widgetList<Checkbox>(find.byType(Checkbox))
              .every((box) => box.value == true),
          isTrue);

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      expect(find.text('1 dipilih'), findsOneWidget);
      expect(api.requests, isEmpty,
          reason: 'selecting must not load details or void anything');
    });

    testWidgets('voided setoran and pencairan cannot join selection at $width',
        (tester) async {
      await pumpPage(tester, width);
      await enterSelection(tester);
      await tester.tap(find.text('Sudah batal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pencairan Ani'));
      await tester.pumpAndSettle();

      expect(find.text('0 dipilih'), findsOneWidget);
      expect(api.requests, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'deselecting the last row keeps mode until explicit exit $width',
        (tester) async {
      await pumpPage(tester, width);
      await enterSelection(tester);
      await tester.tap(find.text('Budi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Budi'));
      await tester.pumpAndSettle();
      expect(find.text('0 dipilih'), findsOneWidget);

      await tester.tap(find.byTooltip('Batal memilih setoran'));
      await tester.pumpAndSettle();
      expect(find.text('0 dipilih'), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
      expect(api.requests, isEmpty);
    });
  }

  testWidgets('changing search or page exits selection', (tester) async {
    await pumpPage(tester, 390);
    await enterSelection(tester);
    await tester.tap(find.text('Budi'));
    await tester.pumpAndSettle();
    feed.changeSearch();
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsNothing);

    await enterSelection(tester);
    await tester.tap(find.text('Budi').last);
    await tester.pumpAndSettle();
    feed.changePage();
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('refresh removes a selection that another pengurus voided',
      (tester) async {
    await pumpPage(tester, 390);
    await enterSelection(tester);
    await tester.tap(find.text('Budi'));
    await tester.pumpAndSettle();
    feed.markFirstVoided();
    await tester.pumpAndSettle();
    expect(find.text('0 dipilih'), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);
  });

  testWidgets('selection controls fit a narrow phone with large text',
      (tester) async {
    await pumpPage(tester, 320, textScale: 2);
    await enterSelection(tester);
    expect(find.text('0 dipilih'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no selectable setoran disables the selection menu entry',
      (tester) async {
    await pumpPage(tester, 390, onlyVoided: true);
    await tester.tap(find.text('Opsi'));
    await tester.pumpAndSettle();
    final entry = tester.widget<PopupMenuItem<String>>(find.ancestor(
        of: find.text('Pilih Setoran'),
        matching: find.byType(PopupMenuItem<String>)));
    expect(entry.enabled, isFalse);
    expect(api.requests, isEmpty);
  });
}
