import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:pilah_mobile/features/onboarding/presentation/widgets/pilih_bank_sampah_bottom_sheet.dart';

import '../../../../support/onboarding_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

const _path = '/api/v1/bank-sampah';

Map<String, dynamic> _bank(String id, String nama, {String kota = 'Depok'}) =>
    {'id': id, 'nama': nama, 'alamat': 'Jl. $nama', 'kota': kota};

void main() {
  late StubApi api;
  late OnboardingCubit cubit;
  BankSampahDirectoryEntity? picked;

  setUp(() {
    api = StubApi();
    cubit = buildOnboardingCubit(api);
    picked = null;
    api.on('GET', _path, json: [
      _bank('b1', 'Bank Melati'),
      _bank('b2', 'Bank Mawar', kota: ''),
    ]);
  });

  tearDown(() => cubit.close());

  Future<void> openSheet(WidgetTester tester,
      {Set<String> excluded = const {}}) async {
    await pumpRouted(
      tester,
      BlocProvider<OnboardingCubit>.value(
        value: cubit,
        child: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                picked = await showModalBottomSheet<BankSampahDirectoryEntity>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => BlocProvider<OnboardingCubit>.value(
                    value: cubit,
                    child:
                        PilihBankSampahBottomSheet(excludedBankIds: excluded),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
      size: const Size(800, 1800),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
  }

  testWidgets('shows a spinner, then the directory', (tester) async {
    await openSheet(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Bank Melati'), findsOneWidget);
    expect(find.text('Depok · Jl. Bank Melati'), findsOneWidget);
    expect(find.text('Jl. Bank Mawar'), findsOneWidget);
  });

  testWidgets('searching narrows the list, with a note when nothing matches',
      (tester) async {
    await openSheet(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'mawar');
    await tester.pump();
    expect(find.text('Bank Melati'), findsNothing);
    expect(find.text('Bank Mawar'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.text('Bank sampah tidak ditemukan.'), findsOneWidget);
  });

  testWidgets('hides banks the nasabah already joined', (tester) async {
    await openSheet(tester, excluded: {'b1'});
    await tester.pumpAndSettle();

    expect(find.text('Bank Melati'), findsNothing);
    expect(find.text('Bank Mawar'), findsOneWidget);
  });

  testWidgets('an empty directory says so', (tester) async {
    api.on('GET', _path, json: <dynamic>[]);
    await openSheet(tester);
    await tester.pumpAndSettle();

    expect(find.text('Belum ada bank sampah yang tersedia.'), findsOneWidget);
  });

  testWidgets('a failed load shows the message and can be retried',
      (tester) async {
    api.on('GET', _path, status: 500, json: {});
    await openSheet(tester);
    await tester.pumpAndSettle();
    expect(find.text('Internal Server Error'), findsOneWidget);

    api.on('GET', _path, json: [_bank('b1', 'Bank Melati')]);
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Bank Melati'), findsOneWidget);
  });

  testWidgets('choosing a bank closes the sheet with it', (tester) async {
    await openSheet(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bank Melati'));
    await tester.pumpAndSettle();

    expect(picked?.id, 'b1');
  });
}
