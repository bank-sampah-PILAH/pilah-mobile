import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/pages/nasabah_page.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/detail_nasabah_bottom_sheet.dart';
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
  });

  tearDown(() => cubit.close());

  Future<void> open(WidgetTester tester) async {
    await pumpRouted(
      tester,
      // A non-const instance so the constructor itself runs.
      // ignore: prefer_const_constructors
      NasabahPage(),
      wrap: (app) => BlocProvider<NasabahCubit>.value(value: cubit, child: app),
      size: const Size(800, 2000),
    );
    await tester.pumpAndSettle();
  }

  void listAs(List<Map<String, dynamic>> rows, {String? status}) {
    api.on('GET', _path, json: nasabahPage(rows));
  }

  testWidgets('lists the active nasabah', (tester) async {
    listAs([
      nasabahRow('1'),
      nasabahRow('2', nama: 'Siti Aminah', active: false),
    ]);
    await open(tester);

    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('Siti Aminah'), findsOneWidget);
  });

  testWidgets('each tab shows its own empty state', (tester) async {
    listAs([]);
    await open(tester);
    expect(find.text('Belum Ada Nasabah'), findsOneWidget);

    await tester.tap(find.text('Tidak Aktif'));
    await tester.pumpAndSettle();
    expect(find.text('Tidak Ada Nasabah Nonaktif'), findsOneWidget);
    expect(api.last.query['status'], 'tidak_aktif');

    await tester.tap(find.text('Menunggu').first);
    await tester.pumpAndSettle();
    expect(find.text('Tidak Ada Pengajuan'), findsOneWidget);
    expect(api.last.query['status'], 'menunggu');

    await tester.tap(find.text('Aktif'));
    await tester.pumpAndSettle();
    expect(find.text('Belum Ada Nasabah'), findsOneWidget);
  });

  testWidgets('searching asks the server and explains an empty result',
      (tester) async {
    listAs([nasabahRow('1')]);
    await open(tester);

    listAs([]);
    await tester.enterText(find.byType(TextField).first, 'zzz');
    await tester.pump(NasabahCubit.jedaPencarian * 2);
    await tester.pumpAndSettle();

    expect(api.last.query['search'], 'zzz');
    expect(find.text('Nasabah Tidak Ditemukan'), findsOneWidget);
  });

  testWidgets('a failed load can be retried by pulling down', (tester) async {
    api.on('GET', _path, status: 500, json: {});
    await open(tester);
    expect(find.text('Gagal Memuat Data'), findsOneWidget);

    listAs([nasabahRow('1')]);
    await tester.drag(find.byType(EmptyView), const Offset(0, 500));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Budi Santoso'), findsOneWidget);
  });

  testWidgets('the add button opens the form', (tester) async {
    listAs([]);
    await open(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(TambahNasabahBottomSheet), findsOneWidget);
  });

  testWidgets('tapping a nasabah opens the detail sheet', (tester) async {
    listAs([nasabahRow('1')]);
    api.on('GET', '$_path/1', json: <String, dynamic>{});
    await open(tester);

    await tester.tap(find.text('Budi Santoso'));
    await tester.pumpAndSettle();

    expect(find.byType(DetailNasabahBottomSheet), findsOneWidget);
  });

  group('pending submissions', () {
    Future<void> openPending(WidgetTester tester) async {
      listAs([nasabahRow('p1', nama: 'Calon Nasabah', status: 'pending')]);
      await open(tester);
      // The first "Menunggu" is the filter chip; the row's badge comes later.
      await tester.tap(find.text('Menunggu').first);
      await tester.pumpAndSettle();
    }

    testWidgets('are marked and offer approve or reject', (tester) async {
      await openPending(tester);
      expect(find.text('Calon Nasabah'), findsOneWidget);

      await tester.tap(find.text('Calon Nasabah'));
      await tester.pumpAndSettle();

      expect(find.text('Setujui'), findsOneWidget);
      expect(find.text('Tolak'), findsOneWidget);
    });

    testWidgets('approving sends the decision', (tester) async {
      api.on('POST', '$_path/p1/approve', json: {});
      await openPending(tester);

      await tester.tap(find.text('Calon Nasabah'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Setujui'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Setujui'));
      await pumpToast(tester);

      expect(api.requests.any((r) => r.path == '$_path/p1/approve'), isTrue);
      await settleToasts(tester);
    });

    testWidgets('a failed decision shows the error', (tester) async {
      api.on('POST', '$_path/p1/reject',
          status: 409, json: {'error': 'Sudah diputuskan'});
      await openPending(tester);

      await tester.tap(find.text('Calon Nasabah'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tolak'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Tolak'));
      await pumpToast(tester);

      expect(find.text('Sudah diputuskan'), findsOneWidget);
      await settleToasts(tester);
    });

    testWidgets('dismissing the action sheet changes nothing', (tester) async {
      await openPending(tester);
      final before = api.requests.length;

      await tester.tap(find.text('Calon Nasabah'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(api.requests.length, before);
    });
  });
}
