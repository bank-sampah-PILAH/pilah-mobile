import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/harga_confirmation_dialog.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/tambah_jenis_sampah_bottom_sheet.dart';

import '../../../../support/harga_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

HargaEntity _existing({bool active = true, String category = 'plastik'}) =>
    HargaEntity(
      id: 'h1',
      kodeSampah: 'PLS-001',
      name: 'Botol PET',
      price: 2500,
      priceFormatted: 'Rp 2500',
      category: category,
      subtitle: 'bening',
      badgeText: 'Anorganik',
      icon: Icons.recycling,
      iconColor: Colors.green,
      isActive: active,
    );

void main() {
  late StubApi api;
  late HargaCubit cubit;

  setUp(() {
    api = StubApi();
    cubit = buildHargaCubit(api);
    api.on('GET', '/api/v1/jenis-sampah', json: {
      'results': [
        {
          'id': 'h1',
          'kode': 'PLS-001',
          'nama_sampah': 'Botol PET',
          'kategori': 'plastik',
          'deskripsi': 'bening',
          'harga_per_kg': '2500',
          'is_active': true,
        },
      ],
    });
  });

  tearDown(() => cubit.close());

  /// Opens the sheet from a launcher button so `context.pop()` has a route to
  /// close, like the real page.
  Future<void> openSheet(WidgetTester tester, {HargaEntity? initial}) async {
    await pumpRouted(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                useRootNavigator: true,
                isScrollControlled: true,
                builder: (_) => BlocProvider<HargaCubit>.value(
                  value: cubit,
                  child: TambahJenisSampahBottomSheet(
                    initialData: initial,
                    hargaCubit: cubit,
                  ),
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
    await tester.pumpAndSettle();
  }

  Future<void> fillForm(WidgetTester tester,
      {String kode = 'NEW-1',
      String nama = 'Kardus',
      String harga = '1500'}) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), kode);
    await tester.enterText(fields.at(1), nama);
    await tester.enterText(fields.at(3), harga);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kertas').last);
    await tester.pumpAndSettle();
  }

  testWidgets('submitting an empty form flags every required field',
      (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('Simpan Jenis Sampah'));
    await pumpToast(tester);

    expect(find.text('Bagian ini wajib diisi.'), findsNWidgets(4));
    expect(api.requests.where((r) => r.method == 'POST'), isEmpty);
    await settleToasts(tester);
  });

  testWidgets('a valid form creates the jenis sampah and confirms',
      (tester) async {
    api.on('POST', '/api/v1/jenis-sampah', status: 201, json: {});
    await openSheet(tester);

    await fillForm(tester);
    await tester.tap(find.text('Simpan Jenis Sampah'));
    await pumpToast(tester);

    final post = api.requests.firstWhere((r) => r.method == 'POST');
    expect(post.json['kode'], 'NEW-1');
    expect(post.json['kategori'], 'kertas');
    expect(post.json['harga_per_kg'], '1500');
    expect(
        find.text('Jenis sampah baru berhasil ditambahkan.'), findsOneWidget);
    expect(find.byType(TambahJenisSampahBottomSheet), findsNothing);
    await settleToasts(tester);
  });

  testWidgets('a code that is already in the list is rejected locally',
      (tester) async {
    await tester.runAsync(cubit.loadHarga);
    await openSheet(tester);

    await fillForm(tester, kode: ' pls-001 ');
    await tester.tap(find.text('Simpan Jenis Sampah'));
    await pumpToast(tester);

    expect(find.text('Kode sampah ini sudah digunakan.'), findsOneWidget);
    expect(api.requests.where((r) => r.method == 'POST'), isEmpty);
    await settleToasts(tester);
  });

  testWidgets('a duplicate code reported by the server lands on the kode field',
      (tester) async {
    api.on('POST', '/api/v1/jenis-sampah', status: 422, json: {
      'errors': {
        'kode': ['Kode dipakai bank lain']
      },
    });
    await openSheet(tester);

    await fillForm(tester);
    await tester.tap(find.text('Simpan Jenis Sampah'));
    await pumpToast(tester);

    expect(find.text('Kode dipakai bank lain'), findsWidgets);
    expect(find.text('Gagal Menyimpan'), findsOneWidget);
    expect(find.byType(TambahJenisSampahBottomSheet), findsOneWidget);

    // Editing the code clears the stale server error.
    await tester.enterText(find.byType(TextFormField).first, 'OTHER');
    await tester.pump();
    await tester.tap(find.text('Simpan Jenis Sampah'));
    await pumpToast(tester);
    await settleToasts(tester);
  });

  testWidgets('edit mode preselects the stored values and saves via PUT',
      (tester) async {
    api.on('PUT', '/api/v1/jenis-sampah/h1', json: {});
    await openSheet(tester, initial: _existing());

    expect(find.text('Edit Jenis Sampah'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'PLS-001'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '2500'), findsOneWidget);
    expect(find.text('Plastik'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), 'Botol Baru');
    await tester.tap(find.text('Simpan Perubahan'));
    await pumpToast(tester);

    final put = api.requests.firstWhere((r) => r.method == 'PUT');
    expect(put.json['nama_sampah'], 'Botol Baru');
    expect(find.text('Jenis sampah berhasil diperbarui.'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('an unknown stored category leaves the dropdown empty',
      (tester) async {
    await openSheet(tester, initial: _existing(category: 'organik'));

    expect(find.text('— Pilih Kategori —'), findsOneWidget);
  });

  testWidgets('deactivating asks first and cancelling changes nothing',
      (tester) async {
    await openSheet(tester, initial: _existing());

    await tester.tap(find.text('Nonaktifkan Jenis Sampah'));
    await tester.pumpAndSettle();
    expect(find.text('Nonaktifkan Jenis Sampah?'), findsOneWidget);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(api.requests.where((r) => r.method == 'PATCH'), isEmpty);
    expect(find.byType(TambahJenisSampahBottomSheet), findsOneWidget);
  });

  testWidgets('confirming deactivation patches the status and closes',
      (tester) async {
    api.on('PATCH', '/api/v1/jenis-sampah/h1/status', json: {});
    await openSheet(tester, initial: _existing());

    await tester.tap(find.text('Nonaktifkan Jenis Sampah'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya, Nonaktifkan'));
    await pumpToast(tester);

    expect(api.requests.firstWhere((r) => r.method == 'PATCH').json,
        {'is_active': false});
    expect(find.text('Jenis sampah berhasil dinonaktifkan.'), findsOneWidget);
    expect(find.byType(TambahJenisSampahBottomSheet), findsNothing);
    await settleToasts(tester);
  });

  testWidgets('an inactive item can be reactivated', (tester) async {
    api.on('PATCH', '/api/v1/jenis-sampah/h1/status', json: {});
    await openSheet(tester, initial: _existing(active: false));

    await tester.tap(find.text('Aktifkan Jenis Sampah'));
    await tester.pumpAndSettle();
    expect(find.text('Aktifkan Jenis Sampah?'), findsOneWidget);
    await tester.tap(find.text('Ya, Aktifkan'));
    await pumpToast(tester);

    expect(api.requests.firstWhere((r) => r.method == 'PATCH').json,
        {'is_active': true});
    expect(find.text('Jenis sampah berhasil diaktifkan.'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('a failed status change reports the error and keeps the sheet',
      (tester) async {
    api.on('PATCH', '/api/v1/jenis-sampah/h1/status',
        status: 403, json: {'error': 'Tidak boleh'});
    await openSheet(tester, initial: _existing());

    await tester.tap(find.text('Nonaktifkan Jenis Sampah'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya, Nonaktifkan'));
    await pumpToast(tester);

    expect(find.text('Tidak boleh'), findsOneWidget);
    expect(find.byType(TambahJenisSampahBottomSheet), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('dismissing the confirmation dialog counts as cancel',
      (tester) async {
    bool? result;
    await pumpRouted(
      tester,
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async => result = await HargaConfirmationDialog.show(
            context,
            isActivating: true,
            wasteName: 'Kaleng',
          ),
          child: const Text('go'),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Aktifkan Jenis Sampah?'), findsOneWidget);

    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });
}
