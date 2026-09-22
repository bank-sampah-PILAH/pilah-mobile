import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_primary_button.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/pencairan/presentation/blocs/pencairan_cubit.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/catat_pencairan_page.dart';

class _MockUseCases extends Mock implements PencairanUseCases {}

final _now = DateTime(2026, 9, 22, 10);

const _created = Pencairan(
  id: 'p-1',
  nasabahNama: 'Ahmad Ridwan',
  nominal: 200000,
  metode: MetodePencairan.transfer,
  tanggal: null,
  keterangan: '',
  status: 'tercatat',
  saldoSebelum: 465600,
  saldoSesudah: 265600,
);

void main() {
  setUpAll(() {
    registerFallbackValue(
      PencairanRequest(
        nasabahId: '',
        nominal: 0,
        metode: MetodePencairan.tunai,
        tanggal: DateTime(2026),
      ),
    );
  });

  late _MockUseCases useCases;

  setUp(() {
    useCases = _MockUseCases();
    when(() => useCases.getSaldo('n-1'))
        .thenAnswer((_) async => const Right(465600));
  });

  Future<void> pumpView(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => PencairanCubit(useCases),
          child: CatatPencairanView(
            nasabahId: 'n-1',
            nasabahNama: 'Ahmad Ridwan',
            now: () => _now,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  CustomPrimaryButton submitButton(WidgetTester tester) =>
      tester.widget(find.byKey(const Key('submit-pencairan')));

  Future<void> enterNominal(WidgetTester tester, String value) async {
    await tester.enterText(find.byKey(const Key('nominal-field')), value);
    await tester.pump();
  }

  testWidgets('shows the current saldo', (tester) async {
    await pumpView(tester);

    expect(find.text('Ahmad Ridwan'), findsOneWidget);
    expect(find.text('Rp 465.600'), findsWidgets);
  });

  testWidgets('keeps submit disabled until the nominal is valid',
      (tester) async {
    await pumpView(tester);
    expect(submitButton(tester).onPressed, isNull);

    await enterNominal(tester, '0');
    expect(submitButton(tester).onPressed, isNull);

    await enterNominal(tester, '465601');
    expect(submitButton(tester).onPressed, isNull);
    expect(find.text('Maksimal Rp 465.600'), findsOneWidget);

    await enterNominal(tester, '200000');
    expect(submitButton(tester).onPressed, isNotNull);
  });

  testWidgets('shows the saldo left after the payout', (tester) async {
    await pumpView(tester);

    await enterNominal(tester, '200000');

    expect(find.text('Rp 265.600'), findsOneWidget);
  });

  testWidgets('confirms, then records the payout with the chosen metode',
      (tester) async {
    when(() => useCases.createPencairan(any()))
        .thenAnswer((_) async => const Right(_created));
    await pumpView(tester);

    await enterNominal(tester, '200000');
    await tester.tap(find.text('Transfer'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('submit-pencairan')));
    await tester.pumpAndSettle();

    expect(
      find.text('Pencairan Rp 200.000 akan dicatat sebagai pembayaran '
          'transfer.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Catat'));
    await tester.pumpAndSettle();

    final sent = verify(() => useCases.createPencairan(captureAny()))
        .captured
        .single as PencairanRequest;
    expect(sent.nasabahId, 'n-1');
    expect(sent.nominal, 200000);
    expect(sent.metode, MetodePencairan.transfer);
    expect(sent.tanggal, _now);
    expect(find.text('Pencairan berhasil dicatat'), findsOneWidget);
    expect(find.text('Rp 265.600'), findsWidgets);
  });

  testWidgets('shows a nominal rejected by the server under the field',
      (tester) async {
    when(() => useCases.createPencairan(any())).thenAnswer(
      (_) async => Left(
        UnprocessableEntityException(
          message: 'Saldo nasabah tidak mencukupi',
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/api/v1/pencairan'),
            statusCode: 422,
            data: {
              'errors': {
                'nominal': ['Saldo nasabah tidak mencukupi'],
              },
            },
          ),
        ),
      ),
    );
    await pumpView(tester);

    await enterNominal(tester, '200000');
    await tester.tap(find.byKey(const Key('submit-pencairan')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Catat'));
    await tester.pumpAndSettle();

    expect(find.text('Saldo nasabah tidak mencukupi'), findsOneWidget);
  });

  testWidgets('does not offer dates after today', (tester) async {
    await pumpView(tester);

    await tester.tap(find.byKey(const Key('tanggal-field')));
    await tester.pumpAndSettle();

    final picker = tester.widget<DatePickerDialog>(
      find.byType(DatePickerDialog),
    );
    expect(picker.lastDate, DateTime(2026, 9, 22));
  });
}
