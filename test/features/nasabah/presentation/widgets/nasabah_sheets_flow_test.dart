import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/detail_nasabah_bottom_sheet.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/edit_nasabah_bottom_sheet.dart';

import '../../../../support/nasabah_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

const _path = '/api/v1/nasabah';

NasabahEntity _nasabah({
  bool active = true,
  String phone = '+628123456789',
  String jk = 'Laki-laki',
  bool punyaAkun = false,
  String id = 'n1',
  String kode = 'NAS-1',
}) =>
    NasabahEntity(
      id: id,
      idNasabah: kode,
      name: 'Budi Santoso',
      email: 'budi@example.com',
      phone: phone,
      balance: 'Rp 450.000',
      isActive: active,
      address: 'Jl. Mawar No. 12',
      initials: 'BS',
      avatarColor: const Color(0xFFEAF5EC),
      textColor: const Color(0xFF2F6B45),
      jenisKelamin: jk,
      tanggalLahir: '01/01/1990',
      tanggalDaftar: '12/05/2026',
      punyaAkun: punyaAkun,
    );

void main() {
  late StubApi api;
  late NasabahCubit cubit;

  setUp(() {
    api = StubApi();
    cubit = buildNasabahCubit(api);
    api.on('GET', _path, json: nasabahPage([]));
    api.on('GET', '$_path/n1', json: <String, dynamic>{});
  });

  tearDown(() => cubit.close());

  Future<void> openSheet(
      WidgetTester tester, Widget Function(BuildContext) sheet) async {
    await pumpRouted(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              useRootNavigator: true,
              isScrollControlled: true,
              builder: sheet,
            ),
            child: const Text('open'),
          ),
        ),
      ),
      // Above the navigator, as in the app, so sheets opened from sheets still
      // find the cubit.
      wrap: (app) => BlocProvider<NasabahCubit>.value(value: cubit, child: app),
      size: const Size(800, 2600),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('detail sheet', () {
    Future<void> openDetail(WidgetTester tester, NasabahEntity n) => openSheet(
        tester,
        (_) => DetailNasabahBottomSheet(nasabah: n, nasabahCubit: cubit));

    testWidgets('deactivating asks first, then reports success',
        (tester) async {
      api.on('PATCH', '$_path/n1/status', json: {});
      await openDetail(tester, _nasabah());

      await tester.ensureVisible(find.text('Nonaktifkan'));
      await tester.tap(find.text('Nonaktifkan'));
      await tester.pumpAndSettle();
      expect(find.text('Nonaktifkan Nasabah?'), findsOneWidget);
      await tester.tap(find.text('Ya, Nonaktifkan'));
      await pumpToast(tester);

      expect(api.requests.firstWhere((r) => r.method == 'PATCH').json,
          {'is_active': false});
      expect(find.text('Budi Santoso telah dinonaktifkan.'), findsOneWidget);
      expect(find.byType(DetailNasabahBottomSheet), findsNothing);
      await settleToasts(tester);
    });

    testWidgets('an inactive nasabah can be reactivated', (tester) async {
      api.on('PATCH', '$_path/n1/status', json: {});
      await openDetail(tester, _nasabah(active: false));

      await tester.ensureVisible(find.text('Aktifkan'));
      await tester.tap(find.text('Aktifkan'));
      await tester.pumpAndSettle();
      expect(find.text('Aktifkan Nasabah?'), findsOneWidget);
      await tester.tap(find.text('Ya, Aktifkan'));
      await pumpToast(tester);

      expect(find.text('Budi Santoso berhasil diaktifkan kembali.'),
          findsOneWidget);
      await settleToasts(tester);
    });

    testWidgets('cancelling leaves everything as it was', (tester) async {
      await openDetail(tester, _nasabah());

      await tester.ensureVisible(find.text('Nonaktifkan'));
      await tester.tap(find.text('Nonaktifkan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(api.requests.where((r) => r.method == 'PATCH'), isEmpty);
      expect(find.byType(DetailNasabahBottomSheet), findsOneWidget);
    });

    testWidgets('a failure keeps the sheet so the user can retry',
        (tester) async {
      api.on('PATCH', '$_path/n1/status',
          status: 403, json: {'error': 'Tidak boleh'});
      await openDetail(tester, _nasabah());

      await tester.ensureVisible(find.text('Nonaktifkan'));
      await tester.tap(find.text('Nonaktifkan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ya, Nonaktifkan'));
      await pumpToast(tester);

      expect(find.text('Tidak boleh'), findsOneWidget);
      expect(find.byType(DetailNasabahBottomSheet), findsOneWidget);
      await settleToasts(tester);
    });

    testWidgets('the nasabah code stands in for a missing id', (tester) async {
      api.on('PATCH', '$_path/NAS-1/status', json: {});
      await openDetail(tester, _nasabah(id: '', kode: 'NAS-1'));

      await tester.ensureVisible(find.text('Nonaktifkan'));
      await tester.tap(find.text('Nonaktifkan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ya, Nonaktifkan'));
      await pumpToast(tester);

      expect(api.requests.any((r) => r.path == '$_path/NAS-1/status'), isTrue);
      await settleToasts(tester);
    });

    testWidgets('the Edit button swaps to the edit form', (tester) async {
      await openDetail(tester, _nasabah());

      await tester.ensureVisible(find.text('Edit Data'));
      await tester.tap(find.text('Edit Data'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Nasabah'), findsOneWidget);
    });

    testWidgets('without a cubit the status button does nothing',
        (tester) async {
      await openSheet(
          tester, (_) => DetailNasabahBottomSheet(nasabah: _nasabah()));

      await tester.ensureVisible(find.text('Nonaktifkan'));
      await tester.tap(find.text('Nonaktifkan'));
      await tester.pumpAndSettle();

      expect(find.text('Nonaktifkan Nasabah?'), findsNothing);
    });
  });

  group('edit sheet', () {
    Future<void> openEdit(WidgetTester tester, NasabahEntity n) =>
        openSheet(tester, (_) => EditNasabahBottomSheet(nasabah: n));

    Finder field(String text) => find.widgetWithText(TextFormField, text);

    Future<void> save(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Simpan Perubahan'));
      await tester.tap(find.text('Simpan Perubahan'));
      await pumpToast(tester);
    }

    testWidgets('strips the country prefix and saves the changes',
        (tester) async {
      api.on('PUT', '$_path/n1', json: nasabahRow('n1'));
      await openEdit(tester, _nasabah());
      expect(field('8123456789'), findsOneWidget);

      await tester.enterText(field('Budi Santoso'), 'Budi Baru');
      await save(tester);

      final put = api.requests.firstWhere((r) => r.method == 'PUT');
      expect(put.json['nama'], 'Budi Baru');
      expect(put.json['no_hp'], '+628123456789');
      expect(find.text('Perubahan data nasabah berhasil disimpan.'),
          findsOneWidget);
      await settleToasts(tester);
    });

    testWidgets('a number with a leading zero or 62 is normalised',
        (tester) async {
      await openEdit(tester, _nasabah(phone: '08123456789'));
      expect(field('8123456789'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());

      await openEdit(tester, _nasabah(phone: '628123456789'));
      expect(field('8123456789'), findsOneWidget);
    });

    testWidgets('an unknown gender leaves the dropdown unset', (tester) async {
      await openEdit(tester, _nasabah(jk: ''));

      await save(tester);

      expect(find.text('Pilih jenis kelamin.'), findsOneWidget);
      await settleToasts(tester);
    });

    testWidgets('choosing a gender from the dropdown makes the form valid',
        (tester) async {
      api.on('PUT', '$_path/n1', json: nasabahRow('n1'));
      await openEdit(tester, _nasabah(jk: ''));

      await tester.ensureVisible(find.text('— Pilih —'));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Perempuan').last);
      await tester.pumpAndSettle();
      await save(tester);

      expect(
          api.requests
              .firstWhere((r) => r.method == 'PUT')
              .json['jenis_kelamin'],
          'perempuan');
      await settleToasts(tester);
    });

    testWidgets('picking a birth date fills the field', (tester) async {
      await openEdit(tester, _nasabah());

      await tester.ensureVisible(field('01/01/1990'));
      await tester.tap(field('01/01/1990'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final today =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      expect(field(today), findsOneWidget);
    });

    testWidgets('a code already used in the list is rejected locally',
        (tester) async {
      api.on('GET', _path, json: nasabahPage([nasabahRow('n2')]));
      await tester.runAsync(cubit.loadNasabah);
      await openEdit(tester, _nasabah());

      await tester.enterText(field('NAS-1'), ' nas-n2 ');
      await save(tester);

      expect(find.text('ID Nasabah ini sudah digunakan.'), findsOneWidget);
      expect(api.requests.where((r) => r.method == 'PUT'), isEmpty);
      await settleToasts(tester);
    });

    testWidgets('server errors land on the kode and email fields',
        (tester) async {
      api.on('PUT', '$_path/n1', status: 422, json: {
        'errors': {
          'kode': ['Kode dipakai'],
          'email': ['Email dipakai'],
        },
      });
      await openEdit(tester, _nasabah());

      await save(tester);

      expect(find.text('Kode dipakai'), findsWidgets);
      expect(find.text('Email dipakai'), findsWidgets);
      expect(find.text('Gagal Menyimpan'), findsOneWidget);
      await settleToasts(tester);

      // Editing the fields drops the stale server messages, so a corrected
      // resubmission goes through.
      api.on('PUT', '$_path/n1', json: nasabahRow('n1'));
      await tester.enterText(field('NAS-1'), 'NAS-2');
      await tester.enterText(field('budi@example.com'), 'baru@example.com');
      await tester.pump();
      await save(tester);
      expect(find.text('Perubahan data nasabah berhasil disimpan.'),
          findsOneWidget);
    });

    testWidgets('a 403 about the account email locks the email field',
        (tester) async {
      api.on('PUT', '$_path/n1',
          status: 403,
          json: {'error': 'Email nasabah dengan akun tidak dapat diubah'});
      await openEdit(tester, _nasabah());

      await save(tester);

      expect(find.text('Email dikelola oleh nasabah'), findsOneWidget);
      await settleToasts(tester);
    });

    testWidgets('a nasabah with an account shows the lock from the start',
        (tester) async {
      await openEdit(tester, _nasabah(punyaAkun: true));

      expect(find.text('Email dikelola oleh nasabah'), findsOneWidget);
    });

    testWidgets('the close button dismisses the form', (tester) async {
      await openEdit(tester, _nasabah());

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      expect(find.text('Edit Nasabah'), findsNothing);
    });
  });
}
