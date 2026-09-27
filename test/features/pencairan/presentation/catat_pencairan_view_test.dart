import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_primary_button.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/core/router/root_navigator_key.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/activate_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/add_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/approve_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/deactivate_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_active_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_nasabah_ringkasan_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/reject_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/update_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/pencairan/presentation/blocs/pencairan_cubit.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/catat_pencairan_page.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_state.dart';

class _MockUseCases extends Mock implements PencairanUseCases {}

class _MockRiwayatAktivitasCubit extends MockCubit<RiwayatAktivitasState>
    implements RiwayatAktivitasCubit {}

class _MockGetNasabahUseCase extends Mock implements GetNasabahUseCase {}

class _MockGetActiveNasabahUseCase extends Mock
    implements GetActiveNasabahUseCase {}

class _MockGetNasabahRingkasanUseCase extends Mock
    implements GetNasabahRingkasanUseCase {}

class _MockAddNasabahUseCase extends Mock implements AddNasabahUseCase {}

class _MockUpdateNasabahUseCase extends Mock implements UpdateNasabahUseCase {}

class _MockActivateNasabahUseCase extends Mock
    implements ActivateNasabahUseCase {}

class _MockDeactivateNasabahUseCase extends Mock
    implements DeactivateNasabahUseCase {}

class _MockApproveNasabahUseCase extends Mock
    implements ApproveNasabahUseCase {}

class _MockRejectNasabahUseCase extends Mock implements RejectNasabahUseCase {}

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
  late _MockRiwayatAktivitasCubit riwayatAktivitasCubit;

  setUp(() {
    useCases = _MockUseCases();
    when(() => useCases.getSaldo('n-1'))
        .thenAnswer((_) async => const Right(465600));
    riwayatAktivitasCubit = _MockRiwayatAktivitasCubit();
    when(() => riwayatAktivitasCubit.state)
        .thenReturn(const RiwayatAktivitasState());
    when(() => riwayatAktivitasCubit.load(silent: any(named: 'silent')))
        .thenAnswer((_) async {});
  });

  final customer = NasabahEntity(
    id: 'n-1',
    idNasabah: 'n-1',
    name: 'Ahmad Ridwan',
    phone: '08123456789',
    balance: 'Rp 0',
    isActive: true,
    address: 'Jl. Melati',
    initials: 'AR',
    avatarColor: const Color(0xFFEAF5EC),
    textColor: const Color(0xFF2F6B45),
    jenisKelamin: 'Laki-laki',
    tanggalLahir: '01/01/1990',
    status: 'approved',
  );

  Future<void> pumpView(WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider<RiwayatAktivitasCubit>.value(
        value: riwayatAktivitasCubit,
        child: MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: BlocProvider(
            create: (_) => PencairanCubit(useCases),
            child: CatatPencairanView(
              initialCustomer: customer,
              now: () => _now,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  CustomPrimaryButton submitButton(WidgetTester tester) =>
      tester.widget(find.byKey(const Key('submit-pencairan')));

  /// The form scrolls on a phone; bring the button on screen before tapping.
  Future<void> tapSubmit(WidgetTester tester) async {
    final submit = find.byKey(const Key('submit-pencairan'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
  }

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
    await tapSubmit(tester);

    expect(
      find.text('Pencairan Rp 200.000 akan dicatat sebagai pembayaran '
          'Transfer.'),
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
    expect(find.text('Pencairan Berhasil!'), findsOneWidget);
    expect(find.text('Rp 265.600'), findsWidgets);

    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();
  });

  testWidgets('cancels the confirmation without creating a payout',
      (tester) async {
    await pumpView(tester);
    await enterNominal(tester, '200000');
    await tapSubmit(tester);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    verifyNever(() => useCases.createPencairan(any()));
    expect(find.byKey(const Key('submit-pencairan')), findsOneWidget);
  });

  testWidgets('retries loading saldo after the first request fails',
      (tester) async {
    when(() => useCases.getSaldo('n-1')).thenAnswer(
      (_) async => Left(NotFoundException(message: 'Saldo tidak tersedia')),
    );
    await pumpView(tester);

    expect(find.text('Gagal memuat saldo. Coba lagi'), findsOneWidget);
    when(() => useCases.getSaldo('n-1'))
        .thenAnswer((_) async => const Right(465600));
    await tester.tap(find.text('Gagal memuat saldo. Coba lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Rp 465.600'), findsOneWidget);
    verify(() => useCases.getSaldo('n-1')).called(2);
  });

  testWidgets('keeps the selected date time when changing the payout date',
      (tester) async {
    when(() => useCases.createPencairan(any()))
        .thenAnswer((_) async => const Right(_created));
    await pumpView(tester);

    await tester.ensureVisible(find.byKey(const Key('tanggal-field')));
    await tester.tap(find.byKey(const Key('tanggal-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('21').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('21 September 2026'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('tanggal-field')));
    await tester.tap(find.byKey(const Key('tanggal-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('22').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await enterNominal(tester, '200000');
    await tapSubmit(tester);
    await tester.tap(find.text('Catat'));
    await tester.pumpAndSettle();

    final sent = verify(() => useCases.createPencairan(captureAny()))
        .captured
        .single as PencairanRequest;
    expect(sent.tanggal, _now);
  });

  testWidgets('shows a notification for a non-field submission failure',
      (tester) async {
    when(() => useCases.createPencairan(any())).thenAnswer(
      (_) async => Left(NetworkException(message: 'Layanan sedang sibuk')),
    );
    await pumpView(tester);

    await enterNominal(tester, '200000');
    await tapSubmit(tester);
    await tester.tap(find.text('Catat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Pencairan gagal'), findsOneWidget);
    expect(find.text('Layanan sedang sibuk'), findsOneWidget);
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
    await tapSubmit(tester);
    await tester.tap(find.text('Catat'));
    await tester.pumpAndSettle();

    expect(find.text('Saldo nasabah tidak mencukupi'), findsOneWidget);
  });

  testWidgets('clears the server nominal error once the nominal is edited',
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
    await tapSubmit(tester);
    await tester.tap(find.text('Catat'));
    await tester.pumpAndSettle();
    expect(find.text('Saldo nasabah tidak mencukupi'), findsOneWidget);

    await enterNominal(tester, '100000');

    expect(find.text('Saldo nasabah tidak mencukupi'), findsNothing);
  });

  testWidgets(
      'styles the METODE label like the other section labels (PILIH NASABAH)',
      (tester) async {
    await pumpView(tester);

    final label = tester.widget<Text>(find.text('METODE'));
    expect(label.style?.fontWeight, FontWeight.bold);
    expect(label.style?.letterSpacing, 1.0);
    expect(label.style?.fontSize, 10);
  });

  testWidgets('styles the metode chips like the app\'s other selector pills',
      (tester) async {
    await pumpView(tester);

    final selected = tester.widget<Container>(
      find.byKey(const Key('metode-chip-tunai')),
    );
    expect(
      (selected.decoration as BoxDecoration).color,
      AppColors.greenDark,
    );

    final unselected = tester.widget<Container>(
      find.byKey(const Key('metode-chip-transfer')),
    );
    expect(
      (unselected.decoration as BoxDecoration).color,
      const Color(0xFFF3F4F6),
    );
  });

  testWidgets('gives the nominal field the app\'s Poppins text style',
      (tester) async {
    await pumpView(tester);

    final field =
        tester.widget<TextField>(find.byKey(const Key('nominal-field')));
    expect(field.style?.fontFamily, contains('Poppins'));
  });

  testWidgets('gives the keterangan field the app\'s Poppins text style',
      (tester) async {
    await pumpView(tester);

    final field =
        tester.widget<TextField>(find.byKey(const Key('keterangan-field')));
    expect(field.style?.fontFamily, contains('Poppins'));
  });

  testWidgets('gives the tanggal value the app\'s Poppins text style',
      (tester) async {
    await pumpView(tester);

    final text = tester.widget<Text>(find.text('22 September 2026'));
    expect(text.style?.fontFamily, contains('Poppins'));
  });

  testWidgets('does not offer dates after today', (tester) async {
    await pumpView(tester);

    await tester.ensureVisible(find.byKey(const Key('tanggal-field')));
    await tester.tap(find.byKey(const Key('tanggal-field')));
    await tester.pumpAndSettle();

    final picker = tester.widget<DatePickerDialog>(
      find.byType(DatePickerDialog),
    );
    expect(picker.lastDate, DateTime(2026, 9, 22));
  });

  group('nasabah picked inline', () {
    late _MockGetNasabahUseCase getUseCase;
    late _MockGetActiveNasabahUseCase getActiveUseCase;
    late NasabahCubit nasabahCubit;

    setUp(() {
      getUseCase = _MockGetNasabahUseCase();
      getActiveUseCase = _MockGetActiveNasabahUseCase();
      nasabahCubit = NasabahCubit(
        getUseCase,
        getActiveUseCase,
        _MockGetNasabahRingkasanUseCase(),
        _MockAddNasabahUseCase(),
        _MockUpdateNasabahUseCase(),
        _MockActivateNasabahUseCase(),
        _MockDeactivateNasabahUseCase(),
        _MockApproveNasabahUseCase(),
        _MockRejectNasabahUseCase(),
      );
    });

    tearDown(() => nasabahCubit.close());

    Future<void> pumpEmptyView(WidgetTester tester) async {
      final router = GoRouter(
        navigatorKey: rootNavigatorKey,
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => BlocProvider(
              create: (_) => PencairanCubit(useCases),
              child: CatatPencairanView(now: () => _now),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<NasabahCubit>.value(value: nasabahCubit),
            BlocProvider<RiwayatAktivitasCubit>.value(
                value: riwayatAktivitasCubit),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows the picker and hides the form until a nasabah is picked',
        (tester) async {
      await pumpEmptyView(tester);

      expect(find.text('Tap untuk pilih nasabah'), findsOneWidget);
      expect(find.byKey(const Key('nominal-field')), findsNothing);
      expect(find.byKey(const Key('submit-pencairan')), findsOneWidget);
      expect(
        tester
            .widget<CustomPrimaryButton>(
                find.byKey(const Key('submit-pencairan')))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('picking a nasabah loads saldo and reveals the form',
        (tester) async {
      when(() => getActiveUseCase.execute()).thenAnswer(
        (_) async => Right(HalamanNasabah(
          items: [customer],
          totalCount: 1,
          hasMore: false,
        )),
      );
      await pumpEmptyView(tester);

      await tester.tap(find.text('Tap untuk pilih nasabah'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ahmad Ridwan'));
      await tester.pumpAndSettle();

      verify(() => useCases.getSaldo('n-1')).called(1);
      expect(find.byKey(const Key('nominal-field')), findsOneWidget);
    });
  });
}
