import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/dashboard/presentation/providers/recent_activity_provider.dart';
import 'package:pilah_mobile/features/dashboard/presentation/states/recent_activity_state.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/recent_activity_section.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';

class _UnusedGetTransaksi extends Mock implements GetTransaksiUseCase {}

class _UnusedPencairanUseCases extends Mock implements PencairanUseCases {}

class _StubRecentActivityNotifier extends RecentActivityNotifier {
  _StubRecentActivityNotifier(this.initialState)
      : super(_UnusedGetTransaksi(), _UnusedPencairanUseCases());

  final RecentActivityState initialState;
  var loadCalls = 0;

  @override
  RecentActivityState build() => initialState;

  @override
  Future<void> load({bool silent = false}) async {
    loadCalls++;
  }

  Future<void> close() async {}
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

Widget _host(_StubRecentActivityNotifier cubit) {
  return ProviderScope(
    overrides: [recentActivityProvider.overrideWith(() => cubit)],
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
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
      final cubit = _StubRecentActivityNotifier(
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
      final cubit = _StubRecentActivityNotifier(
          const RecentActivityError('Koneksi terputus'));
      addTearDown(cubit.close);

      await tester.pumpWidget(_host(cubit));
      await tester.tap(find.text('Coba Lagi'));
      await tester.pump();

      expect(cubit.loadCalls, 1);
    });

    testWidgets('a genuinely empty list still says so', (tester) async {
      final cubit = _StubRecentActivityNotifier(const RecentActivityLoaded([]));
      addTearDown(cubit.close);

      await tester.pumpWidget(_host(cubit));

      expect(find.text('Belum ada aktivitas transaksi.'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsNothing);
    });

    testWidgets('renders every activity with its full date and time',
        (tester) async {
      final cubit = _StubRecentActivityNotifier(RecentActivityLoaded([
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
      final cubit = _StubRecentActivityNotifier(RecentActivityLoaded([
        _pencairan('Ani Wijaya', DateTime(2026, 9, 22, 10)),
        _trx('Budi', tanggal: DateTime(2026, 9, 22, 9)),
      ]));
      addTearDown(cubit.close);

      await tester.pumpWidget(_host(cubit));

      expect(find.text('Ani Wijaya'), findsOneWidget);
      expect(find.text('Budi'), findsOneWidget);
    });

    testWidgets('Lihat Semua opens the laporan tab', (tester) async {
      final cubit = _StubRecentActivityNotifier(RecentActivityLoaded([
        _trx('Budi', tanggal: DateTime(2026, 9, 22, 9)),
      ]));
      addTearDown(cubit.close);
      final router = GoRouter(routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => Scaffold(
            body: ProviderScope(
              overrides: [recentActivityProvider.overrideWith(() => cubit)],
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
    final cubit = _StubRecentActivityNotifier(RecentActivityLoaded([
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
