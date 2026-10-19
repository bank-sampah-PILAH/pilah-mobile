import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/web_content_surface.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_aktivitas_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_entity.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/laporan/laporan_page.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_table.dart';

class _MockGetAktivitasUseCase extends Mock implements GetAktivitasUseCase {}

class _MockExportTransaksiUseCase extends Mock
    implements ExportTransaksiUseCase {}

TransaksiEntity _setoran(String name, DateTime tanggal) => TransaksiEntity(
      initials: 'NN',
      avatarColor: const Color(0xFFEAF5EC),
      textColor: const Color(0xFF2F6B45),
      name: name,
      subtitle: 'Plastik PET • 2 kg',
      amount: '+Rp 7.000',
      isWaSuccess: true,
      time: '08:00',
      balance: 'Rp 0',
      items: const [],
      tanggal: tanggal,
    );

Pencairan _pencairan(String name, DateTime tanggal) => Pencairan(
      id: 'p-1',
      nasabahNama: name,
      nominal: 50000,
      metode: MetodePencairan.tunai,
      tanggal: tanggal,
      keterangan: '',
      status: 'tercatat',
      saldoSebelum: 100000,
      saldoSesudah: 50000,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(const TransaksiFilter());
  });

  late _MockGetAktivitasUseCase getTransaksi;

  setUp(() {
    getTransaksi = _MockGetAktivitasUseCase();
    when(() => getTransaksi.execute(any())).thenAnswer((invocation) async {
      final filter = invocation.positionalArguments.first as TransaksiFilter;
      final items = [
        ActivitasEntity.fromPencairan(
            _pencairan('Ani Wijaya', DateTime(2026, 9, 22, 10))),
        ActivitasEntity.fromTransaksi(
            _setoran('Budi Santoso', DateTime(2026, 9, 22, 8))),
      ]
          .where((item) =>
              (filter.tipe == null ||
                  filter.tipe == 'semua' ||
                  item.tipe.name == filter.tipe) &&
              item.title
                  .toLowerCase()
                  .contains((filter.search ?? '').toLowerCase()))
          .toList();
      return Right(AktivitasPage(items, false));
    });
  });

  Future<void> pumpPage(WidgetTester tester,
      {double textScale = 1, bool inWebShell = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: BlocProvider(
          create: (_) => RiwayatAktivitasCubit(
            getTransaksi,
            _MockExportTransaksiUseCase(),
          ),
          child: inWebShell
              ? const WebContentSurface(child: LaporanPage())
              : const LaporanPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
      'desktop offers every period in one picker and puts search beside the title',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpPage(tester);

    final title = tester.getRect(find.text('Riwayat Aktivitas'));
    final search = tester.getRect(find.byType(TextField));
    expect(search.left, greaterThan(title.right));
    expect(search.top, lessThan(title.bottom));
    expect(search.width, lessThanOrEqualTo(360));
    expect(tester.getSize(find.byType(LaporanPage)).width, 1440);
    expect(find.text('Bulan Ini'), findsOneWidget);
    expect(find.text('Ekspor XLSX'), findsOneWidget);
    await tester.tap(find.text('Bulan Ini'));
    await tester.pumpAndSettle();
    for (final label in ['Hari Ini', 'Minggu Ini', '12 Bulan', 'Semua Waktu']) {
      expect(find.text(label).hitTestable(), findsOneWidget);
    }
    await tester.tap(find.text('12 Bulan'));
    await tester.pumpAndSettle();
    final filter = verify(() => getTransaksi.execute(captureAny()))
        .captured
        .last as TransaksiFilter;
    expect(filter.periode, '12_bulan');
    expect(find.text('Pilih Periode'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  Color pageBackground(WidgetTester tester) => tester
      .widget<Scaffold>(find
          .descendant(
              of: find.byType(LaporanPage), matching: find.byType(Scaffold))
          .first)
      .backgroundColor!;

  testWidgets('the web shell shows the report on a white page', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpPage(tester, inWebShell: true);

    expect(pageBackground(tester), Colors.white);
  });

  testWidgets('the phone layout is white like the other pages', (tester) async {
    await pumpPage(tester);

    expect(pageBackground(tester), Colors.white);
  });

  testWidgets('a wide screen keeps the web gutter around the title',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpPage(tester);

    expect(tester.getTopLeft(find.text('Riwayat Aktivitas')).dx, 32);
    expect(tester.getRect(find.byType(TextField)).right, 1000 - 32);
  });

  testWidgets('the activity list lines up with the header on a wide screen',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpPage(tester);

    expect(tester.getTopLeft(find.byType(AktivitasTable)).dx,
        tester.getTopLeft(find.text('Riwayat Aktivitas')).dx);
  });

  testWidgets('resizing keeps the visible search consistent with the report',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpPage(tester);
    await tester.enterText(find.byType(TextField), 'Ani');
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Ani');
    expect(find.text('Ani Wijaya'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsNothing);
  });

  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('shows both setoran and pencairan in one feed', (tester) async {
    usePhone(tester);
    await pumpPage(tester);

    expect(find.text('Riwayat Aktivitas'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('Ani Wijaya'), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Setoran'), findsOneWidget);
    expect(find.text('Pencairan'), findsOneWidget);
    expect(find.text('22/09/2026'), findsNWidgets(2));
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);
  });

  testWidgets('the Pencairan filter hides setoran rows', (tester) async {
    usePhone(tester);
    await pumpPage(tester);

    await tester.tap(find.text('Pencairan'));
    await tester.pumpAndSettle();

    expect(find.text('Ani Wijaya'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsNothing);
  });

  testWidgets('searching narrows both feeds by name', (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byType(TextField), 'ani');
    await tester.pumpAndSettle();

    expect(find.text('Ani Wijaya'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsNothing);
  });
  testWidgets('the period button and export icon fit without overflow at 360px',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpPage(tester);
    expect(find.text('Bulan Ini'), findsOneWidget);
    expect(find.byTooltip('Ekspor XLSX'), findsOneWidget);
    expect(find.text('Ekspor XLSX'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'short screen with large text can scroll filters to reach activity',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpPage(tester, textScale: 2);
    await tester.drag(find.byType(NestedScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Budi Santoso').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pulling down reloads the feed without clearing it',
      (tester) async {
    await pumpPage(tester);
    clearInteractions(getTransaksi);

    await tester.fling(find.byType(ListView).last, const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    verify(() => getTransaksi.execute(any())).called(1);
    expect(find.text('Budi Santoso'), findsOneWidget);
  });

  testWidgets('resetting the filters also clears the search box',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpPage(tester);
    await tester.enterText(find.byType(TextField), 'Ani');
    await tester.pumpAndSettle();

    tester
        .element(find.byType(LaporanPage))
        .read<RiwayatAktivitasCubit>()
        .resetFilters();
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty);
    expect(find.text('Budi Santoso'), findsOneWidget);
  });
}
