import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/detail_transaksi_bottom_sheet.dart';

import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';
import '../../../../support/transaksi_support.dart';

const _path = '/api/v1/transaksi/t1';

Map<String, dynamic> _row({String wa = 'terkirim'}) => {
      'nasabah_nama': 'Budi',
      'total_nilai': '15000',
      'saldo_setelah_transaksi': '40000',
      'status_wa': wa,
      'items': [
        {
          'nama_sampah_snapshot': 'Botol',
          'berat': '2.5',
          'harga_snapshot': '2000',
          'subtotal': '5000',
        },
      ],
    };

void main() {
  late StubApi api;
  late TransaksiCubit cubit;

  setUp(() {
    api = StubApi();
    cubit = buildTransaksiCubit(api);
  });

  tearDown(() => cubit.close());

  Future<void> open(WidgetTester tester, Map<String, dynamic> data) async {
    await pumpRouted(
      tester,
      BlocProvider<TransaksiCubit>.value(
        value: cubit,
        child: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => BlocProvider<TransaksiCubit>.value(
                  value: cubit,
                  child: DetailTransaksiBottomSheet(transactionData: data),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      size: const Size(800, 2000),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
  }

  Map<String, dynamic> listData({String wa = 'sent', String id = 't1'}) => {
        'id': id,
        'initials': 'BS',
        'avatarColor': Colors.green,
        'textColor': Colors.white,
        'name': 'Budi Santoso',
        'time': '08:00',
        'amount': '+Rp 12.000',
        'balance': '',
        'waStatus': wa,
        'items': [
          {
            'jenis': 'Kardus',
            'berat': '1 kg',
            'harga': 'Rp 1.000',
            'subtotal': 'Rp 1.000'
          },
        ],
      };

  testWidgets('shows the list data first, then the fetched breakdown',
      (tester) async {
    api.on('GET', _path, json: _row());
    await open(tester, listData());

    expect(find.text('Detail Transaksi'), findsOneWidget);
    expect(find.text('Kardus'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('-'), findsOneWidget,
        reason: 'no balance in the list row');

    await tester.pumpAndSettle();

    expect(find.text('Kardus'), findsNothing);
    expect(find.text('Botol'), findsOneWidget);
    expect(find.text('2,5 kg'), findsOneWidget);
    expect(find.text('Rp 15.000'), findsOneWidget);
    expect(find.text('Rp 40.000'), findsOneWidget);
  });

  testWidgets('a spinner shows while the breakdown loads and nothing is known',
      (tester) async {
    api.on('GET', _path, json: _row());
    api.latency = const Duration(milliseconds: 300);
    await open(tester, {...listData(), 'items': <Map<String, dynamic>>[]});
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a failed fetch keeps the list data', (tester) async {
    api.on('GET', _path, status: 404, json: {});
    await open(tester, listData());
    await tester.pumpAndSettle();

    expect(find.text('Kardus'), findsOneWidget);
  });

  testWidgets('keeps the balance from the list row when the fetch fails',
      (tester) async {
    api.on('GET', _path, status: 500, json: {});
    await open(tester, {...listData(), 'balance': 'Rp 5.000'});
    await tester.pumpAndSettle();

    expect(find.text('Rp 5.000'), findsOneWidget);
  });

  testWidgets('a row without an id never calls the API', (tester) async {
    await open(tester, listData(id: ''));
    await tester.pumpAndSettle();

    expect(api.requests, isEmpty);
    expect(find.text('Kardus'), findsOneWidget);
  });

  testWidgets('falls back to defaults for a bare payload', (tester) async {
    await open(tester, <String, dynamic>{});
    await tester.pumpAndSettle();

    expect(find.text('Unknown'), findsOneWidget);
    expect(find.text('NN'), findsOneWidget);
    expect(find.text('Hari ini'), findsOneWidget);
    expect(find.text('Rp 0'), findsOneWidget);
  });
}
