import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/cari_bank/presentation/cubit/cari_bank_cubit.dart';
import 'package:pilah_mobile/features/cari_bank/presentation/pages/cari_bank_page.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../../support/cari_bank_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

const _directory = '/api/v1/bank-sampah';

void main() {
  late StubApi api;
  late CariBankCubit cubit;

  setUp(() {
    api = StubApi();
    cubit = buildCariBankCubit(api);
    // The page resolves its cubit through the DI container itself.
    di.allowReassignment = true;
    di.registerSingleton<CariBankCubit>(cubit);
    addTearDown(() => di.unregister<CariBankCubit>());
  });

  Future<void> pump(WidgetTester tester) => pumpRouted(
        tester,
        const CariBankPage(),
        extraRoutes: ['/cari-bank-sampah/detail'],
        size: const Size(600, 1200),
      );

  testWidgets('shows the loaded rows', (tester) async {
    api.on('GET', _directory,
        json: bankSampahPage([
          bankRow('b1', 'Bank Garis'),
          bankRow('b2', 'Bank Mawar', kota: 'Bogor'),
        ]));

    await pump(tester);

    // The stub answers within a microtask, so the very first frame can already
    // be past loading; pumpAndSettle guards both timings, then we assert rows.
    await tester.pumpAndSettle();
    expect(find.text('Bank Garis'), findsOneWidget);
    expect(find.text('Depok · Jl. Bank Garis'), findsOneWidget);
    expect(find.text('Bogor · Jl. Bank Mawar'), findsOneWidget);
  });

  testWidgets('an empty result shows the not-found note', (tester) async {
    api.on('GET', _directory, json: bankSampahPage(const [], count: 0));

    await pump(tester);
    await tester.pumpAndSettle();
    expect(find.text('Bank Tidak Ditemukan'), findsOneWidget);
  });

  testWidgets('a failing load shows the message with a retry', (tester) async {
    api.on('GET', _directory, status: 500, json: {});

    await pump(tester);
    await tester.pumpAndSettle();
    expect(find.text('Gagal Memuat Bank Sampah'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);

    // Retry hits a healthy backend and shows the list.
    api.on('GET', _directory,
        json: bankSampahPage([bankRow('b1', 'Bank Garis')]));
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Bank Garis'), findsOneWidget);
  });

  testWidgets('tapping a row routes to the detail page with the bank id',
      (tester) async {
    api.on('GET', _directory,
        json: bankSampahPage([bankRow('b9', 'Bank Garis')]));

    await pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bank Garis'));
    await tester.pumpAndSettle();
    expect(find.text('route:/cari-bank-sampah/detail'), findsOneWidget);
  });
}
