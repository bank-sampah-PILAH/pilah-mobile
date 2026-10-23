import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_web_kpi_section.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/total_kas_card.dart';

import '../../../../support/dashboard_support.dart';
import '../../../../support/stub_api.dart';

void main() {
  for (final sample in <String?, String>{
    null: 'Rp —',
    '0': 'Rp 0',
    '-100': 'Rp -100'
  }.entries) {
    testWidgets(
        'phone at 320px displays savings ${sample.key} independently of deposits',
        (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = StubApi();
      api.on('GET', '/api/v1/dashboard/stats', json: {
        'total_nilai_bulan_ini': '999',
        'total_saldo_nasabah': sample.key,
      });
      final dashboard = buildDashboardCubit(api);
      addTearDown(dashboard.close);
      await tester.runAsync(dashboard.loadStats);
      await tester.pumpWidget(BlocProvider.value(
        value: dashboard,
        child: const MaterialApp(
            home: Scaffold(
                body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: TotalKasCard(),
        ))),
      ));
      expect(find.text(sample.value), findsOneWidget);
      expect(find.text('Rp 999'), findsOneWidget);
      expect(find.text('Belum tersedia'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('separates actual savings from unavailable operational cash',
      (tester) async {
    final api = StubApi();
    api.on('GET', '/api/v1/dashboard/stats', json: {
      'total_nilai_bulan_ini': '1234567',
      'total_saldo_nasabah': '9876543',
      'kas_operasional': null,
      'kas_operasional_status': 'belum_tersedia',
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
    expect(find.text('Rp 9.876.543'), findsOneWidget);
    expect(find.text('Saldo Tabungan Nasabah'), findsOneWidget);
    expect(find.text('Kas Operasional'), findsOneWidget);
    expect(find.text('Belum tersedia'), findsOneWidget);
    expect(find.text('Total Kas Bulan Ini'), findsNothing);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('3,5 kg'), findsOneWidget);
    expect(find.text('9 Trx'), findsOneWidget);
    expect(find.text('Nasabah Aktif'), findsOneWidget);
    expect(find.text('Total Sampah Bulan Ini'), findsOneWidget);
    expect(find.text('Total Transaksi Bulan Ini'), findsOneWidget);
  });
}
