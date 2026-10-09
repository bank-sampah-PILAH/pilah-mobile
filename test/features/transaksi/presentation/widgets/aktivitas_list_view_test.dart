import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/edit_pencairan_page.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_list_view.dart';

import '../../../../support/stub_api.dart';
import '../../../../support/transaksi_support.dart';

class _MockRiwayatCubit extends MockCubit<RiwayatAktivitasState>
    implements RiwayatAktivitasCubit {}

final _now = DateTime(2026, 10, 5, 12);

ActivitasEntity _setoran(String name, DateTime? at) =>
    ActivitasEntity.fromTransaksi(TransaksiEntity(
      initials: 'AB',
      avatarColor: Colors.green.shade100,
      textColor: Colors.green,
      name: name,
      subtitle: '2 jenis sampah',
      amount: '+Rp 5.000',
      isWaSuccess: true,
      time: '10:00',
      balance: 'Rp 5.000',
      items: [
        ItemSetoranEntity(
            jenis: 'Plastik',
            berat: '2 kg',
            harga: 'Rp 1.000',
            subtotal: 'Rp 2.000'),
      ],
      tanggal: at,
    ));

ActivitasEntity _pencairan(String name, DateTime at) =>
    ActivitasEntity.fromPencairan(Pencairan(
      id: 'p-1',
      nasabahId: 'n-1',
      nasabahNama: name,
      nominal: 15000,
      metode: MetodePencairan.tunai,
      tanggal: at,
      keterangan: '',
      status: 'tercatat',
      saldoSebelum: 20000,
      saldoSesudah: 5000,
      dicatatOlehNama: 'Ibu Sari',
    ));

void main() {
  late _MockRiwayatCubit cubit;
  late TransaksiCubit transaksi;

  setUp(() {
    cubit = _MockRiwayatCubit();
    transaksi = buildTransaksiCubit(StubApi());
  });

  tearDown(() => transaksi.close());

  Future<void> pumpList(
      WidgetTester tester, RiwayatAktivitasState state) async {
    when(() => cubit.state).thenReturn(state);
    when(() => cubit.load(silent: true)).thenAnswer((_) async {});
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => MultiBlocProvider(
          providers: [
            BlocProvider<RiwayatAktivitasCubit>.value(value: cubit),
            BlocProvider<TransaksiCubit>.value(value: transaksi),
          ],
          child: Scaffold(body: AktivitasListView(now: () => _now)),
        ),
      ),
      GoRoute(
        path: EditPencairanPage.route,
        builder: (context, _) => Scaffold(
          body: TextButton(
              onPressed: () => context.pop(true), child: const Text('simpan')),
        ),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
  }

  testWidgets('shows skeleton rows while the feed loads', (tester) async {
    await pumpList(tester, const RiwayatAktivitasState());
    expect(find.byType(SkeletonListItem), findsWidgets);

    await pumpList(
        tester, const RiwayatAktivitasState(status: AktivitasStatus.loading));
    expect(find.byType(SkeletonListItem), findsWidgets);
  });

  testWidgets('explains a failed load, with a fallback message',
      (tester) async {
    await pumpList(
        tester,
        const RiwayatAktivitasState(
            status: AktivitasStatus.failure, errorMessage: 'Koneksi putus'));
    expect(find.text('Gagal Memuat Data'), findsOneWidget);
    expect(find.text('Koneksi putus'), findsOneWidget);

    await pumpList(
        tester, const RiwayatAktivitasState(status: AktivitasStatus.failure));
    expect(find.text('Terjadi kesalahan'), findsOneWidget);
  });

  testWidgets('distinguishes an empty period from an empty search',
      (tester) async {
    await pumpList(
        tester, const RiwayatAktivitasState(status: AktivitasStatus.loaded));
    expect(find.text('Belum Ada Aktivitas'), findsOneWidget);

    await pumpList(
        tester,
        const RiwayatAktivitasState(
            status: AktivitasStatus.loaded, search: 'zzz'));
    expect(find.text('Aktivitas Tidak Ditemukan'), findsOneWidget);
  });

  testWidgets('groups rows under day headings', (tester) async {
    await pumpList(
        tester,
        RiwayatAktivitasState(status: AktivitasStatus.loaded, items: [
          _setoran('Ani', _now),
          _setoran('Budi', DateTime(2026, 10, 4, 9)),
          _setoran('Citra', DateTime(2026, 10, 2, 9)),
          _setoran('Dewi', null),
        ]));

    expect(find.text('HARI INI'), findsOneWidget);
    expect(find.text('KEMARIN'), findsOneWidget);
    expect(find.text('3 HARI LALU'), findsOneWidget);
    expect(find.text('LAINNYA'), findsOneWidget);
    expect(find.text('Ani'), findsOneWidget);
  });

  testWidgets('tapping a setoran opens its detail sheet', (tester) async {
    await pumpList(
        tester,
        RiwayatAktivitasState(
            status: AktivitasStatus.loaded, items: [_setoran('Ani', _now)]));

    await tester.tap(find.text('Ani'));
    await tester.pumpAndSettle();

    expect(find.text('Plastik'), findsWidgets);
  });

  testWidgets('a saved pencairan edit refreshes the feed silently',
      (tester) async {
    await pumpList(
        tester,
        RiwayatAktivitasState(
            status: AktivitasStatus.loaded, items: [_pencairan('Budi', _now)]));

    await tester.tap(find.text('Budi'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('edit-pencairan')));
    await tester.tap(find.byKey(const Key('edit-pencairan')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('simpan'));
    await tester.pumpAndSettle();

    verify(() => cubit.load(silent: true)).called(1);
  });
}
