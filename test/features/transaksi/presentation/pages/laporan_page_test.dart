import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/riwayat_pencairan_filter.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/laporan/laporan_page.dart';

class _MockGetTransaksiUseCase extends Mock implements GetTransaksiUseCase {}

class _MockPencairanUseCases extends Mock implements PencairanUseCases {}

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
    registerFallbackValue(const RiwayatPencairanFilter());
  });

  late _MockGetTransaksiUseCase getTransaksi;
  late _MockPencairanUseCases pencairanUseCases;

  setUp(() {
    getTransaksi = _MockGetTransaksiUseCase();
    pencairanUseCases = _MockPencairanUseCases();
    when(() => getTransaksi.execute(any())).thenAnswer(
      (_) async => Right([
        TransaksiGroupEntity(
          header: 'HARI INI',
          transactions: [_setoran('Budi Santoso', DateTime(2026, 9, 22, 8))],
        ),
      ]),
    );
    when(() => pencairanUseCases.getRiwayat(any())).thenAnswer(
      (_) async => Right([_pencairan('Ani Wijaya', DateTime(2026, 9, 22, 10))]),
    );
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => RiwayatAktivitasCubit(
            getTransaksi,
            pencairanUseCases,
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
}
