import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/pengumuman/domain/entities/pengumuman_entity.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/cubit/pengumuman_cubit.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/pages/pengumuman_form_page.dart';

import '../../../../support/pengumuman_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

Map<String, dynamic> _row(String id, {String status = 'draft'}) => {
      'id': id,
      'bank_sampah_id': 'bank-1',
      'judul': 'x',
      'isi': 'x',
      'status': status,
    };

void main() {
  // Lets a toast raised directly on this screen finish its slide-in (its
  // dismiss timer only starts then) so expectations can see it.
  Future<void> showToast(WidgetTester tester) async {
    await tester.pump();
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  late StubApi api;

  setUp(() {
    api = StubApi();
    api.on('POST', '/api/v1/pengumuman', json: _row('9'));
    api.on('POST', '/api/v1/pengumuman/9/terbitkan',
        json: _row('9', status: 'terbit'));
    api.on('PATCH', '/api/v1/pengumuman/9', json: _row('9'));
    api.on('GET', '/api/v1/pengumuman',
        json: {'count': 0, 'next': null, 'results': []});
  });

  // The form rides a pushed route over a root page: it has something to pop
  // back to, and the toast can attach to the real root navigator.
  Future<void> openForm(WidgetTester tester, {PengumumanEntity? existing}) =>
      pumpRouted(
        tester,
        BlocProvider<PengumumanCubit>.value(
          value: buildPengumumanCubit(api),
          child: PengumumanFormPage(
              args: PengumumanFormArgs(pengumuman: existing)),
        ),
        pushed: true,
        size: const Size(800, 2000),
      );

  Future<void> fillForm(WidgetTester tester) async {
    // Fields appear in order: judul, then the isi paragraph.
    await tester.enterText(find.byType(TextFormField).at(0), '  Judul Uji  ');
    await tester.enterText(find.byType(TextFormField).at(1), 'Isi.');
    await tester.pump();
  }

  testWidgets('empty fields show the validation message and send nothing',
      (tester) async {
    await openForm(tester);

    await tester.tap(find.text('Simpan Draft'));
    await tester.pump();

    expect(find.text('Judul wajib diisi.'), findsOneWidget);
    expect(api.requests, isEmpty);
  });

  testWidgets('a filled form posts the trimmed judul as a draft',
      (tester) async {
    await openForm(tester);

    await fillForm(tester);
    await tester.tap(find.text('Simpan Draft'));
    await tester.pumpAndSettle();

    expect(
      api.requests.any(
          (call) => call.method == 'POST' && call.path == '/api/v1/pengumuman'),
      isTrue,
    );
    expect(
        api.requests.where((call) => call.method == 'POST').last.json['judul'],
        'Judul Uji');
  });

  testWidgets('a fill failure raises the error toast and keeps the form',
      (tester) async {
    api.on('POST', '/api/v1/pengumuman', status: 422, json: {
      'errors': {
        'judul': ['terlalu panjang']
      }
    });
    await openForm(tester);

    await fillForm(tester);
    await tester.tap(find.text('Simpan Draft'));
    await showToast(tester);
    expect(find.text('Gagal'), findsOneWidget);
    expect(find.byType(PengumumanFormPage), findsOneWidget);
    await settleToasts(tester);
    // The POST already landed; nothing else to drain here.
  });

  testWidgets('Terbitkan Sekarang saves the draft then posts the publish',
      (tester) async {
    await openForm(tester);

    await fillForm(tester);
    await tester.tap(find.text('Terbitkan Sekarang'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await showToast(tester);
    expect(find.text('Pengumuman diterbitkan.'), findsOneWidget);
    expect(find.text('route:/'), findsOneWidget,
        reason: 'the form pops back after publishing');
    await settleToasts(tester);

    expect(
      api.requests
          .lastWhere((call) => call.path.endsWith('/terbitkan'))
          .json['terbit_pada'],
      isNull,
      reason: 'publishing now sends no schedule time',
    );
  });

  testWidgets('Jadwalkan without a pick time asks for one first',
      (tester) async {
    await openForm(tester);

    await fillForm(tester);
    await tester.tap(find.text('Jadwalkan'));
    await tester.pump();

    expect(find.text('Pilih waktu terbit untuk menjadwalkan.'), findsOneWidget);
    expect(
      api.requests.any((call) => call.path.endsWith('/terbitkan')),
      isFalse,
    );
  });

  testWidgets('a save that returns no id reports the missing anchor',
      (tester) async {
    api.on('POST', '/api/v1/pengumuman', json: _row(''));
    await openForm(tester);

    await fillForm(tester);
    await tester.tap(find.text('Terbitkan Sekarang'));
    await showToast(tester);
    expect(find.text('Pengumuman belum tersimpan.'), findsOneWidget);
    await settleToasts(tester);
    expect(
      api.requests.any((call) => call.path.endsWith('/terbitkan')),
      isFalse,
    );
  });

  testWidgets('a failed publish raises the error and keeps the form',
      (tester) async {
    api.on('POST', '/api/v1/pengumuman/9/terbitkan',
        status: 400, json: {'error': 'tidak diizinkan'});
    await openForm(tester);

    await fillForm(tester);
    await tester.tap(find.text('Terbitkan Sekarang'));
    await showToast(tester);
    expect(find.text('Gagal'), findsOneWidget);
    expect(find.byType(PengumumanFormPage), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('the terbit picker sets the schedule and a later clear drops it',
      (tester) async {
    await openForm(tester);

    // Open the schedule picker: accept the proposed date, then the time.
    await tester.tap(find.text('Belum dipilih').first);
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Belum dipilih'), findsOneWidget,
        reason: 'only the optional masa berlaku field is still empty');
    expect(find.byIcon(Icons.close), findsOneWidget);

    // Clearing the schedule returns the field to its hint.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(find.text('Belum dipilih'), findsNWidgets(2));
  });

  testWidgets('picking masa berlaku equal to the schedule trips the check',
      (tester) async {
    await openForm(tester);

    // Both pickers accept their default: tomorrow, the current time. The
    // expiry then equals the schedule, which the form rejects.
    await tester.tap(find.text('Belum dipilih').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Belum dipilih').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await fillForm(tester);
    await tester.tap(find.text('Simpan Draft'));
    await tester.pump();

    expect(find.text('Judul wajib diisi.'), findsNothing);
    expect(
        find.text('Masa berlaku harus setelah waktu terbit.'), findsOneWidget);
  });

  testWidgets('a masa berlaku without a schedule saves with the expiry set',
      (tester) async {
    await openForm(tester);

    await tester.tap(find.text('Belum dipilih').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // No schedule time: the expiry is judged against now and passes.
    // Clearing the expiry drops it from the next save.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    await fillForm(tester);
    await tester.tap(find.text('Simpan Draft'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await showToast(tester);

    final create = api.requests.lastWhere((call) => call.method == 'POST');
    expect(create.json['masa_berlaku_hingga'], isNull,
        reason: 'the cleared expiry is not sent');
    expect(create.json['terbit_pada'], isNull);
    expect(find.text('Pengumuman disimpan sebagai draft.'), findsOneWidget);
    expect(find.text('route:/'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('an edit form prefills and patches instead of posting',
      (tester) async {
    await openForm(
      tester,
      existing: const PengumumanEntity(
        id: '9',
        bankSampahId: 'bank-1',
        judul: 'Judul lama',
        isi: 'Isi lama',
        status: 'draft',
      ),
    );

    expect(find.text('Ubah Pengumuman'), findsOneWidget);
    expect(find.text('Simpan Draft'), findsOneWidget);
    expect(find.text('Terbitkan Sekarang'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Judul baru');
    await tester.tap(find.text('Simpan Draft'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await showToast(tester);
    expect(find.text('Pengumuman diperbarui.'), findsOneWidget);
    expect(find.text('route:/'), findsOneWidget);
    await settleToasts(tester);

    expect(
        api.requests.where((call) => call.method == 'PATCH').last.json['judul'],
        'Judul baru');
  });

  testWidgets('a scheduled row saves its schedule without re-publishing',
      (tester) async {
    await openForm(
      tester,
      existing: PengumumanEntity(
        id: '9',
        bankSampahId: 'bank-1',
        judul: 'Judul',
        isi: 'Isi',
        terbitPada: DateTime(2026, 12, 1, 9),
        status: 'terjadwal',
      ),
    );

    expect(find.text('Simpan Perubahan'), findsOneWidget);
    expect(find.text('Terbitkan Sekarang'), findsNothing,
        reason: 'a scheduled row has no publish row on offer');

    await tester.enterText(find.byType(TextFormField).at(0), 'Judul jadwal');
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await showToast(tester);
    expect(find.text('Pengumuman diperbarui.'), findsOneWidget);
    expect(find.text('route:/'), findsOneWidget);
    await settleToasts(tester);

    expect(
      api.requests.where((call) => call.path.endsWith('/terbitkan')),
      isEmpty,
    );
    expect(
        api.requests.lastWhere((call) => call.method == 'PATCH').json['judul'],
        'Judul jadwal');
  });

  testWidgets('Jadwalkan with a picked time saves the schedule',
      (tester) async {
    await openForm(tester);

    await tester.tap(find.text('Belum dipilih').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await fillForm(tester);
    await tester.tap(find.text('Jadwalkan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await showToast(tester);

    // The created draft carries the picked schedule and the publish action
    // repeats it for the terjadwal stamp.
    final publish =
        api.requests.lastWhere((call) => call.path.endsWith('/terbitkan'));
    expect(publish.json['terbit_pada'], isNotNull);
    expect(find.text('route:/'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('a failed reload on the shared cubit raises the error toast',
      (tester) async {
    api.fail('GET', '/api/v1/pengumuman');
    final cubit = buildPengumumanCubit(api);
    await pumpRouted(
      tester,
      BlocProvider<PengumumanCubit>.value(
        value: cubit,
        child: const PengumumanFormPage(),
      ),
      pushed: true,
      size: const Size(800, 2000),
    );

    // No await: the load settles across the fake-async pumps instead.
    unawaited(cubit.loadPengumuman());
    await tester.pump();
    for (var i = 0; i < 12 && find.text('Gagal').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Gagal'), findsOneWidget);
    await settleToasts(tester);
  });
}
