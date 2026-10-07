import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/recent_activity_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/recent_activity_state.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/recent_activity_section.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';

/// Stands in for the real cubit so the widget can be driven through each state
/// without touching the network or the DI graph.
class _StubRecentActivityCubit extends Cubit<RecentActivityState>
    implements RecentActivityCubit {
  _StubRecentActivityCubit(super.initialState);

  var loadCalls = 0;

  @override
  Future<void> load({bool silent = false}) async {
    loadCalls++;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _today = DateTime(2026, 9, 22, 12);

ActivitasEntity _trx(String name, {DateTime? tanggal}) =>
    ActivitasEntity.fromTransaksi(TransaksiEntity(
      id: name,
      initials: name.substring(0, 2).toUpperCase(),
      avatarColor: const Color(0xFF000000),
      textColor: const Color(0xFFFFFFFF),
      name: name,
      subtitle: 'Plastik • 2 kg',
      amount: '+Rp 10.000',
      isWaSuccess: true,
      balance: '',
      items: const [],
      tanggal: tanggal,
    ));

ActivitasEntity _pencairan(String name, DateTime tanggal) =>
    ActivitasEntity.fromPencairan(Pencairan(
      id: name,
      nasabahNama: name,
      nominal: 50000,
      metode: MetodePencairan.tunai,
      tanggal: tanggal,
      keterangan: '',
      status: 'tercatat',
      saldoSebelum: 100000,
      saldoSesudah: 50000,
    ));

Widget _host(RecentActivityCubit cubit) {
  return MaterialApp(
    home: Scaffold(
      body: BlocProvider<RecentActivityCubit>.value(
        value: cubit,
        child: SingleChildScrollView(
          child: RecentActivitySection(now: () => _today),
        ),
      ),
    ),
  );
}

void main() {
  group('RecentActivitySection', () {
    testWidgets('a failed fetch is not disguised as "no transactions yet"',
        (tester) async {
      final cubit = _StubRecentActivityCubit(
          const RecentActivityError('Koneksi terputus'));
      addTearDown(cubit.close);

      await tester.pumpWidget(_host(cubit));

      expect(
        find.text('Belum ada aktivitas transaksi.'),
        findsNothing,
        reason: 'an error must not read as an empty list — they mean opposite '
            'things and send the user chasing the wrong problem',
      );
      expect(find.text('Koneksi terputus'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('the error state offers a working retry', (tester) async {
      final cubit = _StubRecentActivityCubit(
          const RecentActivityError('Koneksi terputus'));
      addTearDown(cubit.close);

      await tester.pumpWidget(_host(cubit));
      await tester.tap(find.text('Coba Lagi'));
      await tester.pump();

      expect(cubit.loadCalls, 1);
    });

    testWidgets('a genuinely empty list still says so', (tester) async {
      final cubit = _StubRecentActivityCubit(const RecentActivityLoaded([]));
      addTearDown(cubit.close);

      await tester.pumpWidget(_host(cubit));

      expect(find.text('Belum ada aktivitas transaksi.'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsNothing);
    });

    testWidgets('renders every activity with its full date and time',
        (tester) async {
      final cubit = _StubRecentActivityCubit(RecentActivityLoaded([
        _trx('Budi', tanggal: DateTime(2026, 9, 22, 9)),
        _trx('Sari', tanggal: DateTime(2026, 9, 10, 9)),
        _trx('Andi', tanggal: DateTime(2026, 9, 10, 8)),
      ]));
      addTearDown(cubit.close);

      await tester.pumpWidget(_host(cubit));

      expect(find.text('Budi'), findsOneWidget);
      expect(find.text('Sari'), findsOneWidget);
      expect(
        find.text('Andi'),
        findsOneWidget,
        reason: 'a transaction from months ago is still recent activity when '
            'nothing newer exists — the section is not scoped to a period',
      );
      expect(find.text('22/09/2026'), findsOneWidget);
      expect(find.text('10/09/2026'), findsNWidgets(2));
      expect(find.text('09:00'), findsNWidgets(2));
      expect(find.text('08:00'), findsOneWidget);
    });

    testWidgets('renders a pencairan row alongside setoran', (tester) async {
      final cubit = _StubRecentActivityCubit(RecentActivityLoaded([
        _pencairan('Ani Wijaya', DateTime(2026, 9, 22, 10)),
        _trx('Budi', tanggal: DateTime(2026, 9, 22, 9)),
      ]));
      addTearDown(cubit.close);

      await tester.pumpWidget(_host(cubit));

      expect(find.text('Ani Wijaya'), findsOneWidget);
      expect(find.text('Budi'), findsOneWidget);
    });

    testWidgets('Lihat Semua opens the laporan tab', (tester) async {
      final cubit = _StubRecentActivityCubit(RecentActivityLoaded([
        _trx('Budi', tanggal: DateTime(2026, 9, 22, 9)),
      ]));
      addTearDown(cubit.close);
      final router = GoRouter(routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => Scaffold(
            body: BlocProvider<RecentActivityCubit>.value(
              value: cubit,
              child: RecentActivitySection(now: () => _today),
            ),
          ),
        ),
        GoRoute(
          path: '/laporan',
          builder: (_, __) => const Scaffold(body: Text('Laporan')),
        ),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      await tester.tap(find.text('Lihat Semua'));
      await tester.pumpAndSettle();

      expect(find.text('Laporan'), findsOneWidget);
    });
  });
  testWidgets('legacy activity without captions uses its day label',
      (tester) async {
    final cubit = _StubRecentActivityCubit(RecentActivityLoaded([
      ActivitasEntity(
          tipe: ActivitasTipe.setoran,
          tanggal: _today,
          avatarText: 'AB',
          avatarColor: Colors.green,
          avatarTextColor: Colors.white,
          title: 'Legacy',
          subtitleLines: const [],
          amount: '+Rp 1.000',
          searchTerm: 'Legacy')
    ]));
    addTearDown(cubit.close);
    await tester.pumpWidget(_host(cubit));
    expect(find.text('Hari ini'), findsOneWidget);
  });
}
