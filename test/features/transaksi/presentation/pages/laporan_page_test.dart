import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_aktivitas_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_entity.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/laporan/laporan_page.dart';

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

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => RiwayatAktivitasCubit(
            getTransaksi,
            _MockExportTransaksiUseCase(),
          ),
          child: const LaporanPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows both setoran and pencairan in one feed', (tester) async {
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
  testWidgets('day and week filters are visible without overflow at 360px',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpPage(tester);
    expect(find.text('Hari Ini'), findsOneWidget);
    expect(find.text('Minggu Ini'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
