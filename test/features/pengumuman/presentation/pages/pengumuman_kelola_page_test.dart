import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/pengumuman/data/datasources/pengumuman_remote_data_source.dart';
import 'package:pilah_mobile/features/pengumuman/data/repositories/pengumuman_repository_impl.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/cubit/pengumuman_cubit.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/pages/pengumuman_kelola_page.dart';

import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

Map<String, dynamic> _row(String id,
    {required String judul, required String status}) => {
      'id': id,
      'judul': judul,
      'isi': 'Isi $id.',
      'status': status,
      'terbit_pada': '2026-10-15T03:00:00Z',
      'dibuat_oleh_id': 'u1',
    };

void main() {
  // Drains a just-shown (two post-frame callbacks away) toast in one stretch:
  // the stepwise settleToasts drive hits a flushbar pop race on this route.
  Future<void> drainToast(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }


  late StubApi api;
  late PengumumanCubit cubit;

  setUp(() {
    api = StubApi();
    cubit = PengumumanCubit(
        PengumumanRepositoryImpl(PengumumanRemoteDataSourceImpl(api.network)));
  });

  tearDown(() => cubit.close());

  Future<void> openPage(WidgetTester tester) async {
    await pumpRouted(
      tester,
      BlocProvider<PengumumanCubit>.value(
        value: cubit,
        child: const PengumumanKelolaPage(),
      ),
      size: const Size(800, 2000),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders rows with their status and the filter chips',
      (tester) async {
    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 2,
      'next': null,
      'results': [
        _row('1', judul: 'Masih konsep', status: 'draft'),
        _row('2', judul: 'Sedang berjalan', status: 'terbit'),
      ],
    });

    await openPage(tester);

    expect(find.byKey(const ValueKey('pengumuman-kelola-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('pengumuman-kelola-2')), findsOneWidget);
    // The row badge and the filter chip both say "Draft".
    expect(find.text('Draft'), findsNWidgets(2));
    expect(find.widgetWithText(ChoiceChip, 'Semua'), findsOneWidget);
    // Draft rows can be edited; terbit rows can be withdrawn.
    expect(find.text('Ubah'), findsOneWidget);
    expect(find.text('Hapus'), findsOneWidget);
    expect(find.text('Tarik'), findsOneWidget);
  });

  testWidgets('filtering sends the status and swaps the rows', (tester) async {
    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 1,
      'next': null,
      'results': [_row('1', judul: 'Masih konsep', status: 'draft')],
    });
    await openPage(tester);

    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 0,
      'next': null,
      'results': <Map<String, dynamic>>[],
    });
    await tester.tap(find.widgetWithText(ChoiceChip, 'Kedaluwarsa'));
    await tester.pumpAndSettle();

    expect(api.last.query['status'], 'kedaluwarsa');
    expect(find.text('Tidak ada pengumuman dengan status ini'), findsOneWidget);
  });

  testWidgets('a declined withdrawal confirmation stays inert', (tester) async {
    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 1,
      'next': null,
      'results': [_row('1', judul: 'Sedang berjalan', status: 'terbit')],
    });
    await openPage(tester);

    await tester.tap(find.text('Tarik'));
    await tester.pumpAndSettle();
    expect(find.text('Tarik pengumuman?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Batal').last);
    await tester.pumpAndSettle();
    expect(find.text('Tarik pengumuman?'), findsNothing);
    expect(
      api.requests.where((call) => call.path.contains('tarik')),
      isEmpty,
    );
  });

  testWidgets('confirming the withdrawal posts to tarik', (tester) async {
    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 1,
      'next': null,
      'results': [_row('1', judul: 'Sedang berjalan', status: 'terbit')],
    });
    api.on('POST', '/api/v1/pengumuman/1/tarik', json: {'id': '1'});
    await openPage(tester);

    await tester.tap(find.text('Tarik'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Tarik').last);
    await drainToast(tester);

    expect(
      api.requests.any((call) => call.path == '/api/v1/pengumuman/1/tarik'),
      isTrue,
    );
    // The list reloads after the transition.
    expect(
      api.requests.where((call) =>
          call.method == 'GET' && call.path == '/api/v1/pengumuman'),
      hasLength(2),
    );
  });

  testWidgets('canceling a schedule patches the row with a null terbit_pada',
      (tester) async {
    api.on('GET', '/api/v1/pengumuman', json: {
      'count': 1,
      'next': null,
      'results': [
        _row('1', judul: 'Menunggu jadwal', status: 'terjadwal'),
      ],
    });
    api.on('PATCH', '/api/v1/pengumuman/1', json: <String, dynamic>{});
    await openPage(tester);

    await tester.tap(find.text('Batalkan Jadwal'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Batalkan').last);
    await drainToast(tester);

    final call = api.requests.lastWhere((call) => call.method == 'PATCH');
    expect(call.json['terbit_pada'], isNull);
  });
}
