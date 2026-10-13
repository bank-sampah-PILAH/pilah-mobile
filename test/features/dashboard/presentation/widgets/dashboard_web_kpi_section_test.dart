import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_web_kpi_section.dart';

import '../../../../support/dashboard_support.dart';
import '../../../../support/stub_api.dart';

void main() {
  testWidgets('shows the four existing metrics from DashboardCubit',
      (tester) async {
    final api = StubApi();
    api.on('GET', '/api/v1/dashboard/stats', json: {
      'total_nilai_bulan_ini': '1234567',
      'nasabah_aktif': 12,
      'total_sampah_kg_bulan_ini': '3.5',
      'transaksi_bulan_ini': 9,
    });
    final dashboard = buildDashboardCubit(api);
    addTearDown(dashboard.close);

    await tester.pumpWidget(BlocProvider.value(
      value: dashboard,
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: DashboardWebKpiSection()),
        ),
      ),
    ));

    expect(find.text('Rp —'), findsOneWidget);
    await tester.runAsync(dashboard.loadStats);
    await tester.pumpAndSettle();

    expect(find.text('Rp 1.234.567'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('3,5 kg'), findsOneWidget);
    expect(find.text('9 Trx'), findsOneWidget);
    expect(find.text('Nasabah Aktif'), findsOneWidget);
    expect(find.text('Total Sampah Bulan Ini'), findsOneWidget);
    expect(find.text('Total Transaksi Bulan Ini'), findsOneWidget);
  });
}
