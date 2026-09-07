import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_state.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/tambah_nasabah_bottom_sheet.dart';

class MockNasabahCubit extends MockCubit<NasabahState>
    implements NasabahCubit {}

const _duplicatePhoneMessage = 'Nomor HP nasabah sudah digunakan';

/// The exact payload the live API returns when a phone number is already
/// registered to another nasabah in the same bank sampah.
NetworkException _duplicatePhoneException() =>
    NetworkException.handleBadResponse(
      Response(
        requestOptions: RequestOptions(path: '/api/v1/nasabah'),
        statusCode: 422,
        data: {
          'errors': {
            'no_hp': [_duplicatePhoneMessage],
          },
        },
      ),
    );

Widget _host(NasabahCubit cubit) => MaterialApp(
      home: BlocProvider<NasabahCubit>.value(
        value: cubit,
        child: const Scaffold(body: TambahNasabahBottomSheet()),
      ),
    );

/// Fills every field the client-side validators require, so submitting reaches
/// the network call instead of stopping at local validation.
Future<void> _fillValidForm(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'Budi Santoso');
  await tester.enterText(find.byType(TextFormField).at(1), 'NAS-0900');

  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Laki-laki').last);
  await tester.pumpAndSettle();

  // Tanggal lahir is read-only and opens a date picker; any valid past date works.
  await tester.tap(find.byType(TextFormField).at(2));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextFormField).at(3), '81234567890');
  await tester.enterText(
      find.byType(TextFormField).at(4), 'Jl. Melati No. 3, RT 01/RW 02');
  await tester.pumpAndSettle();
}

Future<void> _submit(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(ElevatedButton, 'Simpan Nasabah'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    registerFallbackValue(NasabahRequest(
      kode: '',
      nama: '',
      jenisKelamin: '',
      tanggalLahir: '',
      noHp: '',
      alamat: '',
    ));
  });

  group('422 duplicate-phone parsing', () {
    test('maps the no_hp payload to a field error rather than a bare message',
        () {
      final exception = _duplicatePhoneException();

      expect(exception, isA<UnprocessableEntityException>());
      expect(exception.fieldError(['no_hp', 'no_whatsapp', 'phone']),
          _duplicatePhoneMessage);
    });

    test('reports no phone field error for failures that lack one', () {
      final serverError = NetworkException.handleBadResponse(
        Response(
          requestOptions: RequestOptions(path: '/api/v1/nasabah'),
          statusCode: 500,
          data: null,
        ),
      );

      expect(serverError.fieldError(['no_hp', 'no_whatsapp', 'phone']), isNull,
          reason: 'a 5xx must still escalate to the global notification');
    });
  });

  group('TambahNasabahBottomSheet duplicate phone', () {
    late MockNasabahCubit cubit;

    setUp(() {
      cubit = MockNasabahCubit();
      when(() => cubit.state).thenReturn(const NasabahLoaded(nasabahList: []));
    });

    testWidgets(
        'renders the backend message inline and suppresses the global '
        'error notification', (tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(() => cubit.addNasabah(any()))
          .thenAnswer((_) async => _duplicatePhoneException());

      await tester.pumpWidget(_host(cubit));
      await _fillValidForm(tester);
      await _submit(tester);

      expect(find.text(_duplicatePhoneMessage), findsOneWidget);
      expect(
        find.text('Gagal Menyimpan'),
        findsNothing,
        reason: 'a field-attributable 422 belongs under the input, not in a '
            'global notification',
      );
    });

    testWidgets('clears the inline error as soon as the number is edited',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(() => cubit.addNasabah(any()))
          .thenAnswer((_) async => _duplicatePhoneException());

      await tester.pumpWidget(_host(cubit));
      await _fillValidForm(tester);
      await _submit(tester);
      expect(find.text(_duplicatePhoneMessage), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(3), '81234567899');
      await tester.pumpAndSettle();

      expect(find.text(_duplicatePhoneMessage), findsNothing);
    });
  });
}
