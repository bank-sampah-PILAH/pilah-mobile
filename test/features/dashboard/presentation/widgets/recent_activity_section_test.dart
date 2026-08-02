import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/recent_activity_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/recent_activity_state.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/recent_activity_section.dart';
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

TransaksiEntity _trx(String name) => TransaksiEntity(
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
    );

Widget _host(RecentActivityCubit cubit) {
  return MaterialApp(
    home: Scaffold(
      body: BlocProvider<RecentActivityCubit>.value(
        value: cubit,
        child: const SingleChildScrollView(child: RecentActivitySection()),
      ),
    ),
  );
}

void main() {
  group('RecentActivitySection', () {
    testWidgets('a failed fetch is not disguised as "no transactions yet"',
        (tester) async {
      final cubit =
          _StubRecentActivityCubit(const RecentActivityError('Koneksi terputus'));
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
      final cubit =
          _StubRecentActivityCubit(const RecentActivityError('Koneksi terputus'));
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

    testWidgets('renders every transaction the cubit hands it, day label and all',
        (tester) async {
      final cubit = _StubRecentActivityCubit(RecentActivityLoaded([
        TransaksiGroupEntity(header: 'HARI INI', transactions: [_trx('Budi')]),
        TransaksiGroupEntity(
          header: '12 HARI LALU',
          transactions: [_trx('Sari'), _trx('Andi')],
        ),
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
      expect(find.text('Hari ini'), findsOneWidget);
      expect(find.text('12 hari lalu'), findsNWidgets(2));
    });
  });
}
