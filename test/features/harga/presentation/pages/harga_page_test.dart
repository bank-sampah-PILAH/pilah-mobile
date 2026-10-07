import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';
import 'package:pilah_mobile/features/harga/presentation/pages/harga_page.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/tambah_jenis_sampah_bottom_sheet.dart';

import '../../../../support/harga_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

Map<String, dynamic> _row(String id, String nama,
        {bool active = true, String kategori = 'plastik'}) =>
    {
      'id': id,
      'kode': 'K-$id',
      'nama_sampah': nama,
      'kategori': kategori,
      'deskripsi': 'desk $nama',
      'harga_per_kg': '2500',
      'is_active': active,
    };

void main() {
  late StubApi api;
  late HargaCubit cubit;

  Future<void> openPage(WidgetTester tester) async {
    await pumpRouted(
      tester,
      BlocProvider<HargaCubit>.value(value: cubit, child: const HargaPage()),
      size: const Size(800, 1600),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    api = StubApi();
    cubit = buildHargaCubit(api);
    api.on('GET', '/api/v1/jenis-sampah', json: {
      'results': [
        _row('1', 'Botol PET'),
        _row('2', 'Kardus', kategori: 'kertas'),
        _row('3', 'Kaleng', active: false, kategori: 'logam'),
      ],
    });
  });

  tearDown(() => cubit.close());

  testWidgets('lists active jenis sampah with their price', (tester) async {
    await openPage(tester);

    expect(find.text('Jenis Sampah & Harga'), findsOneWidget);
    expect(find.text('Botol PET'), findsOneWidget);
    expect(find.text('Kardus'), findsOneWidget);
    expect(find.text('Kaleng'), findsNothing);
    expect(find.text('Rp 2500'), findsNWidgets(2));
  });

  testWidgets('the Tidak Aktif chip switches to deactivated items',
      (tester) async {
    await openPage(tester);

    await tester.tap(find.text('Tidak Aktif'));
    await tester.pumpAndSettle();
    expect(find.text('Kaleng'), findsOneWidget);
    expect(find.text('Botol PET'), findsNothing);

    await tester.tap(find.text('Aktif'));
    await tester.pumpAndSettle();
    expect(find.text('Botol PET'), findsOneWidget);
  });

  testWidgets('search filters, and an empty result says nothing matched',
      (tester) async {
    await openPage(tester);

    await tester.enterText(find.byType(TextField).first, 'kardus');
    await tester.pumpAndSettle();
    expect(find.text('Kardus'), findsOneWidget);
    expect(find.text('Botol PET'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('Jenis Sampah Tidak Ditemukan'), findsOneWidget);
  });

  testWidgets('empty tabs explain themselves', (tester) async {
    api.on('GET', '/api/v1/jenis-sampah', json: {'results': []});
    await openPage(tester);
    expect(find.text('Belum Ada Jenis Sampah'), findsOneWidget);

    await tester.tap(find.text('Tidak Aktif'));
    await tester.pumpAndSettle();
    expect(find.text('Tidak Ada Jenis Nonaktif'), findsOneWidget);
  });

  testWidgets('a failed load shows the message and can be retried by pulling',
      (tester) async {
    api.on('GET', '/api/v1/jenis-sampah',
        status: 400, json: {'error': 'Server sibuk'});
    await openPage(tester);
    expect(find.text('Gagal Memuat Data'), findsOneWidget);
    expect(find.text('Server sibuk'), findsOneWidget);

    api.on('GET', '/api/v1/jenis-sampah', json: {
      'results': [_row('1', 'Botol PET')],
    });
    await tester.fling(find.byType(EmptyView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Botol PET'), findsOneWidget);
  });

  testWidgets('shows skeletons until the first load completes', (tester) async {
    await pumpRouted(
      tester,
      BlocProvider<HargaCubit>.value(value: cubit, child: const HargaPage()),
      size: const Size(800, 1600),
    );
    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('Botol PET'), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('the add button opens the empty form', (tester) async {
    await openPage(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(TambahJenisSampahBottomSheet), findsOneWidget);
    expect(find.text('Tambah Jenis Sampah'), findsOneWidget);
  });

  testWidgets('tapping a card opens the edit form prefilled', (tester) async {
    await openPage(tester);

    await tester.tap(find.text('Botol PET'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Jenis Sampah'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Botol PET'), findsOneWidget);
  });
}
