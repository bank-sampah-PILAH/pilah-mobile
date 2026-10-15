import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/tambah_nasabah_bottom_sheet.dart';

import '../../../../support/nasabah_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

const _path = '/api/v1/nasabah';

void main() {
  late StubApi api;
  late NasabahCubit cubit;

  setUp(() {
    api = StubApi();
    cubit = buildNasabahCubit(api);
    api.on('GET', _path, json: nasabahPage([]));
  });

  tearDown(() => cubit.close());

  Future<void> open(WidgetTester tester) async {
    await pumpRouted(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              useRootNavigator: true,
              isScrollControlled: true,
              builder: (_) => const TambahNasabahBottomSheet(),
            ),
            child: const Text('open'),
          ),
        ),
      ),
      wrap: (app) => BlocProvider<NasabahCubit>.value(value: cubit, child: app),
      size: const Size(800, 2600),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester,
      {String kode = 'NAS-9', String email = 'siti@x.test'}) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Siti Aminah');
    await tester.enterText(fields.at(1), kode);
    await tester.ensureVisible(find.text('— Pilih —'));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perempuan').last);
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(2), email);
    await tester.ensureVisible(fields.at(3));
    await tester.tap(fields.at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(4), '81234567890');
    await tester.enterText(fields.at(5), 'Jl. Melati Nomor 5');
  }

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Simpan Nasabah'));
    await tester.tap(find.text('Simpan Nasabah'));
    await pumpToast(tester);
  }

  testWidgets('a valid form creates the nasabah and confirms', (tester) async {
    api.on('POST', _path, status: 201, json: nasabahRow('9'));
    await open(tester);

    await fill(tester);
    await save(tester);

    final post = api.requests.firstWhere((r) => r.method == 'POST');
    expect(post.json['kode'], 'NAS-9');
    expect(post.json['no_hp'], '+6281234567890');
    expect(post.json['jenis_kelamin'], 'perempuan');
    expect(find.text('Nasabah baru berhasil ditambahkan.'), findsOneWidget);
    expect(find.byType(TambahNasabahBottomSheet), findsNothing);
    await settleToasts(tester);
  });

  testWidgets('an empty form flags the required fields', (tester) async {
    await open(tester);

    await save(tester);

    expect(find.text('Bagian ini wajib diisi.'), findsWidgets);
    expect(find.text('Email wajib diisi.'), findsOneWidget);
    expect(find.text('Nomor WhatsApp wajib diisi.'), findsOneWidget);
    expect(api.requests.where((r) => r.method == 'POST'), isEmpty);
    await settleToasts(tester);
  });

  testWidgets('a duplicate code in the loaded list is caught before saving',
      (tester) async {
    api.on('GET', _path, json: nasabahPage([nasabahRow('2')]));
    await tester.runAsync(cubit.loadNasabah);
    await open(tester);

    await fill(tester, kode: 'nas-2');
    await save(tester);

    expect(find.text('ID Nasabah Sudah Digunakan'), findsOneWidget);
    expect(api.requests.where((r) => r.method == 'POST'), isEmpty);
    await settleToasts(tester);

    // Editing the code clears the red border state.
    await tester.enterText(find.byType(TextFormField).at(1), 'NAS-3');
    await tester.pump();
  });

  testWidgets('a duplicate code reported by the server is shown as a toast',
      (tester) async {
    api.on('POST', _path, status: 422, json: {
      'errors': {
        'kode': ['Kode sudah dipakai bank lain']
      },
    });
    await open(tester);

    await fill(tester);
    await save(tester);

    expect(find.text('Kode sudah dipakai bank lain'), findsOneWidget);
    expect(find.byType(TambahNasabahBottomSheet), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('an email error from the server is inline and clears on edit',
      (tester) async {
    api.on('POST', _path, status: 422, json: {
      'errors': {
        'email': ['Email sudah terdaftar']
      },
    });
    await open(tester);
    await fill(tester);

    await save(tester);
    expect(find.text('Email sudah terdaftar'), findsOneWidget);

    api.on('POST', _path, status: 201, json: nasabahRow('9'));
    await tester.enterText(find.byType(TextFormField).at(2), 'lain@x.test');
    await tester.pump();
    await save(tester);
    expect(find.text('Nasabah baru berhasil ditambahkan.'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('a phone error from the server is inline', (tester) async {
    api.on('POST', _path, status: 422, json: {
      'errors': {
        'no_hp': ['Nomor sudah dipakai']
      },
    });
    await open(tester);
    await fill(tester);

    await save(tester);

    expect(find.text('Nomor sudah dipakai'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('any other failure is reported as a toast', (tester) async {
    api.on('POST', _path, status: 500, json: {});
    await open(tester);
    await fill(tester);

    await save(tester);

    expect(find.text('Gagal Menyimpan'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('the close button dismisses the form', (tester) async {
    await open(tester);

    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();

    expect(find.byType(TambahNasabahBottomSheet), findsNothing);
  });
}
