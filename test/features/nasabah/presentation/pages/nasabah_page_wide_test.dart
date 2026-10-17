import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/bases/widgets/bottom_sheet_header.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/pages/nasabah_page.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/detail_nasabah_bottom_sheet.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_table.dart';
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

  Future<void> open(WidgetTester tester,
      {Size size = const Size(1280, 900)}) async {
    await pumpRouted(
      tester,
      NasabahPage(),
      wrap: (app) => BlocProvider<NasabahCubit>.value(value: cubit, child: app),
      size: size,
    );
    await tester.pumpAndSettle();
  }

  void listAs(List<Map<String, dynamic>> rows) {
    api.on('GET', _path, json: nasabahPage(rows));
  }

  testWidgets('a wide screen lists nasabah in a table with a count footer',
      (tester) async {
    listAs([nasabahRow('1'), nasabahRow('2', nama: 'Siti Aminah')]);
    await open(tester);

    expect(find.byType(NasabahTable), findsOneWidget);
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('Siti Aminah'), findsOneWidget);
    expect(find.text('Menampilkan 2 dari 2'), findsOneWidget);
  });

  testWidgets('a phone keeps the list instead of the table', (tester) async {
    listAs([nasabahRow('1')]);
    await open(tester, size: const Size(590, 2000));

    expect(find.byType(NasabahTable), findsNothing);
    expect(find.text('Budi Santoso'), findsOneWidget);
  });

  testWidgets('a wide screen with no nasabah explains the empty state',
      (tester) async {
    listAs([]);
    await open(tester);

    expect(find.text('Belum Ada Nasabah'), findsOneWidget);
  });

  testWidgets('a failed load shows the error', (tester) async {
    api.on('GET', _path, status: 500, json: {});
    await open(tester);

    expect(find.text('Gagal Memuat Data'), findsOneWidget);
  });

  testWidgets('searching asks the server', (tester) async {
    listAs([nasabahRow('1')]);
    await open(tester);

    listAs([]);
    await tester.enterText(find.byType(TextField).first, 'zzz');
    await tester.pump(NasabahCubit.jedaPencarian * 2);
    await tester.pumpAndSettle();

    expect(api.last.query['search'], 'zzz');
    expect(find.text('Nasabah Tidak Ditemukan'), findsOneWidget);
  });

  testWidgets('the add button opens the form in a dialog, not a sheet',
      (tester) async {
    listAs([]);
    await open(tester);

    await tester.tap(find.text('Tambah Nasabah'));
    await tester.pumpAndSettle();

    expect(find.byType(TambahNasabahBottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('a row opens the detail in a dialog', (tester) async {
    listAs([nasabahRow('1')]);
    api.on('GET', '$_path/1', json: <String, dynamic>{});
    await open(tester);

    await tester.tap(find.text('Budi Santoso'));
    await tester.pumpAndSettle();

    expect(find.byType(DetailNasabahBottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
  });

  testWidgets('a phone still opens the detail as a bottom sheet',
      (tester) async {
    listAs([nasabahRow('1')]);
    api.on('GET', '$_path/1', json: <String, dynamic>{});
    await open(tester, size: const Size(590, 2000));

    await tester.tap(find.text('Budi Santoso'));
    await tester.pumpAndSettle();

    expect(find.byType(DetailNasabahBottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(find.byKey(DetailNasabahBottomSheet.dragHandleKey), findsOneWidget);
  });

  testWidgets('the table header sits on the fill colour', (tester) async {
    listAs([nasabahRow('1')]);
    await open(tester);

    final header = tester.widget<Container>(find.byKey(NasabahTable.headerKey));
    expect(header.color, AppColors.fill);
  });

  testWidgets('the detail action is an outlined button', (tester) async {
    listAs([nasabahRow('1')]);
    await open(tester);

    expect(find.widgetWithText(OutlinedButton, 'Lihat detail'), findsOneWidget);
  });

  group('a dialog has no drag handle', () {
    testWidgets('on the add form', (tester) async {
      listAs([]);
      await open(tester);

      await tester.tap(find.text('Tambah Nasabah'));
      await tester.pumpAndSettle();

      expect(
          tester
              .widget<BottomSheetHeader>(find.byType(BottomSheetHeader))
              .showDragHandle,
          isFalse);
    });

    testWidgets('on the detail', (tester) async {
      listAs([nasabahRow('1')]);
      api.on('GET', '$_path/1', json: <String, dynamic>{});
      await open(tester);

      await tester.tap(find.text('Budi Santoso'));
      await tester.pumpAndSettle();

      expect(find.byKey(DetailNasabahBottomSheet.dragHandleKey), findsNothing);
    });

    testWidgets('on the edit form', (tester) async {
      listAs([nasabahRow('1')]);
      api.on('GET', '$_path/1', json: <String, dynamic>{});
      await open(tester);
      await tester.tap(find.text('Budi Santoso'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit Data'));
      await tester.pumpAndSettle();

      expect(
          tester
              .widget<BottomSheetHeader>(find.byType(BottomSheetHeader))
              .showDragHandle,
          isFalse);
    });
  });

  group('pending submissions', () {
    Future<void> openPending(WidgetTester tester) async {
      listAs([nasabahRow('p1', nama: 'Calon Nasabah', status: 'pending')]);
      await open(tester);
      await tester.tap(find.text('Menunggu').first);
      await tester.pumpAndSettle();
    }

    testWidgets('approve and reject sit on the row', (tester) async {
      await openPending(tester);

      expect(find.widgetWithText(FilledButton, 'Setujui'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Tolak'), findsOneWidget);
    });

    testWidgets('approving from the row sends the decision', (tester) async {
      api.on('POST', '$_path/p1/approve', json: {});
      await openPending(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Setujui'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Setujui'));
      await pumpToast(tester);

      expect(api.requests.any((r) => r.path == '$_path/p1/approve'), isTrue);
      await settleToasts(tester);
    });

    testWidgets('rejecting from the row sends the decision', (tester) async {
      api.on('POST', '$_path/p1/reject', json: {});
      await openPending(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Tolak'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Tolak'));
      await pumpToast(tester);

      expect(api.requests.any((r) => r.path == '$_path/p1/reject'), isTrue);
      await settleToasts(tester);
    });
  });
}
