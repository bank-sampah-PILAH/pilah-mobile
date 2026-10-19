import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/design/widgets/app_field_label.dart';
import 'package:pilah_mobile/design/widgets/app_back_header.dart';
import 'package:pilah_mobile/design/widgets/app_chip.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/core/router/root_navigator_key.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/pencairan/presentation/blocs/edit_pencairan_cubit.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/edit_pencairan_page.dart';

class _MockUseCases extends Mock implements PencairanUseCases {}

final _now = DateTime(2026, 9, 22, 10);

final _pencairan = Pencairan(
  id: 'p-1',
  nasabahNama: 'Ahmad Ridwan',
  nominal: 200000,
  metode: MetodePencairan.tunai,
  tanggal: DateTime(2026, 9, 21, 9, 30),
  keterangan: 'Diambil pagi',
  status: 'tercatat',
  saldoSebelum: 465600,
  saldoSesudah: 265600,
  tanggalEditMinimum: DateTime(2026, 9, 14, 9, 30),
);

void main() {
  setUpAll(() {
    registerFallbackValue(
      EditPencairanRequest(
        id: '',
        nominal: 0,
        metode: MetodePencairan.tunai,
        tanggal: DateTime(2026),
        keterangan: '',
        alasan: '',
      ),
    );
  });

  late _MockUseCases useCases;

  setUp(() => useCases = _MockUseCases());

  /// Opens the form from a parent route so the popped result can be read.
  Future<List<Object?>> pumpView(
    WidgetTester tester, {
    Pencairan? pencairan,
  }) async {
    final results = <Object?>[];
    final record = pencairan ?? _pencairan;
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: rootNavigatorKey,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => results.add(
              await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => EditPencairanCubit(useCases),
                    child: EditPencairanView(
                      pencairan: record,
                      now: () => _now,
                    ),
                  ),
                ),
              ),
            ),
            child: const Text('buka'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
    return results;
  }

  AppButton submitButton(WidgetTester tester) =>
      tester.widget(find.byKey(const Key('submit-edit-pencairan')));

  Future<void> tapSubmit(WidgetTester tester) async {
    final submit = find.byKey(const Key('submit-edit-pencairan'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
  }

  testWidgets('keeps the form to a readable column on a desktop window',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpView(tester);

    final field = find.byKey(const Key('nominal-field'));
    expect(tester.getSize(field).width,
        lessThanOrEqualTo(LayoutBreakpoint.formMaxWidth));
    expect(tester.getCenter(field).dx, closeTo(720, 1),
        reason: 'centred in the window');
    final scroll =
        find.ancestor(of: field, matching: find.byType(SingleChildScrollView));
    expect(tester.getSize(scroll.first).width, 1440,
        reason: 'the form scrolls across the window: scrollbar at the edge');
    final submit = find.byKey(const Key('submit-edit-pencairan'));
    expect(field.hitTestable(), findsOneWidget,
        reason: 'the form is not squeezed out by the save bar');
    expect(find.byKey(const Key('alasan-field')), findsOneWidget);
    expect(tester.getSize(submit).width,
        lessThanOrEqualTo(LayoutBreakpoint.formMaxWidth),
        reason: 'the save button is not as wide as the window');
  });

  testWidgets('starts from the recorded values and states the tanggal limit',
      (tester) async {
    await pumpView(tester);

    expect(find.text('200000'), findsOneWidget);
    expect(find.text('Diambil pagi'), findsOneWidget);
    expect(
      find.text('Tanggal hanya bisa dimundurkan sampai 14 September 2026'),
      findsOneWidget,
    );
  });

  group('looks like the catat form', () {
    testWidgets('has a white page headed by the back button, not an app bar',
        (tester) async {
      await pumpView(tester);

      expect(find.byType(AppBar), findsNothing);
      expect(
          find.widgetWithText(AppBackHeader, 'Edit Pencairan'), findsOneWidget);
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold).last).backgroundColor,
        Colors.white,
      );
    });

    testWidgets('captions every field above it, with no floating label',
        (tester) async {
      await pumpView(tester);

      for (final caption in [
        'NOMINAL',
        'METODE',
        'TANGGAL',
        'KETERANGAN (OPSIONAL)',
        'ALASAN PERUBAHAN',
      ]) {
        expect(find.widgetWithText(AppFieldLabel, caption), findsOneWidget,
            reason: caption);
      }
      for (final key in ['nominal-field', 'keterangan-field', 'alasan-field']) {
        expect(
          tester.widget<TextField>(find.byKey(Key(key))).decoration?.labelText,
          isNull,
          reason: key,
        );
      }
    });

    testWidgets('keeps the submit button at the foot, out of the scroll',
        (tester) async {
      await pumpView(tester);

      expect(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byKey(const Key('submit-edit-pencairan')),
        ),
        findsNothing,
      );
      expect(find.byKey(const Key('submit-edit-pencairan')), findsOneWidget);
    });
  });

  testWidgets('offers the metode as the same chips as the catat form',
      (tester) async {
    await pumpView(tester);

    AppChip chip(MetodePencairan metode) =>
        tester.widget(find.byKey(Key('metode-chip-${metode.name}')));
    expect(chip(MetodePencairan.tunai).selected, isTrue);
    expect(chip(MetodePencairan.transfer).selected, isFalse);

    await tester.tap(find.byKey(const Key('metode-chip-transfer')));
    await tester.pump();

    expect(chip(MetodePencairan.tunai).selected, isFalse);
    expect(chip(MetodePencairan.transfer).selected, isTrue);
  });

  testWidgets('keeps submit disabled until an alasan and valid nominal',
      (tester) async {
    await pumpView(tester);
    expect(submitButton(tester).onPressed, isNull);

    await tester.enterText(
        find.byKey(const Key('alasan-field')), 'Salah ketik');
    await tester.pump();
    expect(submitButton(tester).onPressed, isNotNull);

    await tester.enterText(find.byKey(const Key('nominal-field')), '0');
    await tester.pump();
    expect(submitButton(tester).onPressed, isNull);
    expect(find.text('Nominal harus lebih dari nol'), findsOneWidget);
  });

  testWidgets('confirms, saves the edit, and closes with a refresh signal',
      (tester) async {
    when(() => useCases.editPencairan(any())).thenAnswer(
      (_) async => Right(Pencairan(
        id: 'p-1',
        nasabahNama: 'Ahmad Ridwan',
        nominal: 150000,
        metode: MetodePencairan.transfer,
        tanggal: _pencairan.tanggal,
        keterangan: 'Diambil pagi',
        status: 'tercatat',
        saldoSebelum: 465600,
        saldoSesudah: 315600,
        diperbarui: true,
      )),
    );
    final results = await pumpView(tester);

    await tester.enterText(find.byKey(const Key('nominal-field')), '150000');
    await tester.tap(find.text('Transfer'));
    await tester.enterText(
        find.byKey(const Key('alasan-field')), 'Salah ketik');
    await tester.pump();
    await tapSubmit(tester);
    expect(find.text('Simpan perubahan pencairan?'), findsOneWidget);
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    final sent = verify(() => useCases.editPencairan(captureAny()))
        .captured
        .single as EditPencairanRequest;
    expect(sent.id, 'p-1');
    expect(sent.nominal, 150000);
    expect(sent.metode, MetodePencairan.transfer);
    expect(sent.tanggal, _pencairan.tanggal);
    expect(sent.keterangan, 'Diambil pagi');
    expect(sent.alasan, 'Salah ketik');
    expect(results, [true]);
  });

  testWidgets('shows a nominal the server rejected on the nominal field',
      (tester) async {
    when(() => useCases.editPencairan(any())).thenAnswer(
      (_) async => Left(UnprocessableEntityException(
        message: 'Saldo nasabah tidak mencukupi untuk perubahan ini',
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/pencairan/p-1'),
          statusCode: 422,
          data: {
            'errors': {
              'nominal': ['Saldo nasabah tidak mencukupi untuk perubahan ini'],
            },
          },
        ),
      )),
    );
    await pumpView(tester);

    await tester.enterText(find.byKey(const Key('nominal-field')), '300000');
    await tester.enterText(
        find.byKey(const Key('alasan-field')), 'Salah ketik');
    await tester.pump();
    await tapSubmit(tester);
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(
      find.text('Saldo nasabah tidak mencukupi untuk perubahan ini'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('submit-edit-pencairan')), findsOneWidget);
  });

  testWidgets('cancels the edit confirmation without sending a request',
      (tester) async {
    await pumpView(tester);
    await tester.enterText(
        find.byKey(const Key('alasan-field')), 'Salah ketik');
    await tester.pump();
    await tapSubmit(tester);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    verifyNever(() => useCases.editPencairan(any()));
    expect(find.text('Edit Pencairan'), findsOneWidget);
  });

  testWidgets('clamps an edit to the server minimum timestamp', (tester) async {
    final pencairan = Pencairan(
      id: 'p-1',
      nasabahNama: 'Ahmad Ridwan',
      nominal: 200000,
      metode: MetodePencairan.tunai,
      tanggal: DateTime(2026, 9, 21, 8),
      keterangan: 'Diambil pagi',
      status: 'tercatat',
      saldoSebelum: 465600,
      saldoSesudah: 265600,
      tanggalEditMinimum: DateTime(2026, 9, 14, 9, 30),
    );
    when(() => useCases.editPencairan(any()))
        .thenAnswer((_) async => Right(_pencairan));
    final results = await pumpView(tester, pencairan: pencairan);

    await tester.tap(find.byKey(const Key('tanggal-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('14').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('alasan-field')), 'Perbaikan');
    await tester.pump();
    await tapSubmit(tester);
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    final sent = verify(() => useCases.editPencairan(captureAny()))
        .captured
        .single as EditPencairanRequest;
    expect(sent.tanggal, DateTime(2026, 9, 14, 9, 30));
    expect(results, [true]);
  });

  testWidgets('clamps an edit date to now when the recorded time is later',
      (tester) async {
    final pencairan = Pencairan(
      id: 'p-1',
      nasabahNama: 'Ahmad Ridwan',
      nominal: 200000,
      metode: MetodePencairan.tunai,
      tanggal: DateTime(2026, 9, 22, 23),
      keterangan: 'Diambil pagi',
      status: 'tercatat',
      saldoSebelum: 465600,
      saldoSesudah: 265600,
      tanggalEditMinimum: DateTime(2026, 9, 14),
    );
    when(() => useCases.editPencairan(any()))
        .thenAnswer((_) async => Right(_pencairan));
    await pumpView(tester, pencairan: pencairan);

    await tester.tap(find.byKey(const Key('tanggal-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('22').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('alasan-field')), 'Perbaikan');
    await tester.pump();
    await tapSubmit(tester);
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    final sent = verify(() => useCases.editPencairan(captureAny()))
        .captured
        .single as EditPencairanRequest;
    expect(sent.tanggal, _now);
  });

  testWidgets('shows a notification for an edit failure without field errors',
      (tester) async {
    when(() => useCases.editPencairan(any())).thenAnswer(
      (_) async => Left(NetworkException(message: 'Perubahan ditolak')),
    );
    await pumpView(tester);
    await tester.enterText(
        find.byKey(const Key('alasan-field')), 'Salah ketik');
    await tester.pump();
    await tapSubmit(tester);
    await tester.tap(find.text('Simpan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Perubahan gagal disimpan'), findsOneWidget);
    expect(find.text('Perubahan ditolak'), findsOneWidget);
  });

  group('a pencairan with a potongan', () {
    final berpotongan = Pencairan(
      id: 'p-2',
      nasabahNama: 'Ahmad Ridwan',
      nominal: 100000,
      potongan: 10000,
      metode: MetodePencairan.transfer,
      tanggal: DateTime(2026, 9, 21, 9, 30),
      keterangan: '',
      status: 'tercatat',
      saldoSebelum: 465600,
      saldoSesudah: 365600,
      tanggalEditMinimum: DateTime(2026, 9, 14, 9, 30),
    );

    testWidgets('locks the nominal and tanggal and says why', (tester) async {
      await pumpView(tester, pencairan: berpotongan);

      expect(
          tester
              .widget<TextField>(find.byKey(const Key('nominal-field')))
              .enabled,
          isFalse);
      expect(
          find.textContaining('hanya metode dan keterangan'), findsOneWidget);
      await tester.tap(find.byKey(const Key('tanggal-field')));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsNothing);
    });

    testWidgets(
        'still lets the metode be corrected, sending the values as recorded',
        (tester) async {
      when(() => useCases.editPencairan(any()))
          .thenAnswer((_) async => Right(berpotongan));
      await pumpView(tester, pencairan: berpotongan);

      await tester.tap(find.text('Tunai'));
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('alasan-field')), 'Dibayar tunai');
      await tester.pump();
      await tapSubmit(tester);
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      final request = verify(() => useCases.editPencairan(captureAny()))
          .captured
          .single as EditPencairanRequest;
      expect(request.nominal, 100000);
      expect(request.tanggal, DateTime(2026, 9, 21, 9, 30));
      expect(request.metode, MetodePencairan.tunai);
    });
  });

  testWidgets('the embedded header closes the surface it sits in',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      navigatorKey: rootNavigatorKey,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => EditPencairanCubit(useCases),
              child: Scaffold(
                body: EditPencairanView(
                    pencairan: _pencairan, embedded: true, now: () => _now),
              ),
            ),
          )),
          child: const Text('buka'),
        ),
      ),
    ));
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Pencairan'), findsOneWidget);

    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Pencairan'), findsNothing);
    expect(find.text('buka'), findsOneWidget);
  });
}
