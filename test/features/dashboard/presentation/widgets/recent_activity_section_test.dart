import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/recent_activity_section.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_state.dart';

/// Stands in for the real cubit so the widget can be driven through each state
/// without touching the network or the DI graph.
class _StubTransaksiCubit extends Cubit<TransaksiState> implements TransaksiCubit {
  _StubTransaksiCubit(super.initialState);

  var loadCalls = 0;

  @override
  Future<void> loadTransaksi({bool silent = false}) async {
    loadCalls++;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _host(TransaksiCubit cubit) {
  return MaterialApp(
    home: Scaffold(
      body: BlocProvider<TransaksiCubit>.value(
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
      final cubit = _StubTransaksiCubit(const TransaksiError('Koneksi terputus'));
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
      final cubit = _StubTransaksiCubit(const TransaksiError('Koneksi terputus'));
      addTearDown(cubit.close);

      await tester.pumpWidget(_host(cubit));
      await tester.tap(find.text('Coba Lagi'));
      await tester.pump();

      expect(cubit.loadCalls, 1);
    });

    testWidgets('a genuinely empty list still says so', (tester) async {
      final cubit = _StubTransaksiCubit(
        const TransaksiLoaded(transaksiList: []),
      );
      addTearDown(cubit.close);

      await tester.pumpWidget(_host(cubit));

      expect(find.text('Belum ada aktivitas transaksi.'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsNothing);
    });
  });
}
