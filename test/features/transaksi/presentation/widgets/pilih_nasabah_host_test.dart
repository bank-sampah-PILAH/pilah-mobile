import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/pilih_nasabah_section.dart';

import '../../../../support/nasabah_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

/// The nasabah picker is always a bottom sheet, which is the right container on
/// a phone and the wrong one in a browser window: it anchors to the bottom edge
/// and takes 85% of the window height, so on a 1280×800 monitor it is a
/// full-width band of mostly whitespace, far from where the pengelola just
/// clicked.
///
/// On a wide window the same content belongs in a centred dialog. What must not
/// change is the outcome — picking a nasabah still reports that nasabah — so
/// these tests check the container *and* that the result still comes back
/// through it.
void main() {
  late StubApi api;
  late NasabahCubit cubit;
  NasabahEntity? chosen;

  setUp(() {
    api = StubApi();
    cubit = buildNasabahCubit(api);
    chosen = null;
  });

  tearDown(() => cubit.close());

  Future<void> open(WidgetTester tester, Size window) async {
    await pumpRouted(
      tester,
      Scaffold(
        body: PilihNasabahSection(
          selectedCustomer: null,
          onCustomerSelected: (n) => chosen = n,
        ),
      ),
      wrap: (app) =>
          BlocProvider<NasabahCubit>.value(value: cubit, child: app),
      size: window,
    );
    await tester.tap(find.text('Tap untuk pilih nasabah'));
    await tester.pumpAndSettle();
  }

  group('the picker container follows the window width', () {
    testWidgets('a phone keeps the bottom sheet', (tester) async {
      api.on('GET', '/api/v1/nasabah', json: nasabahPage([]));
      await open(tester, const Size(390, 844));

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(Dialog), findsNothing,
          reason: 'a centred dialog on a 390px window is cramped; the sheet '
              'is the right container there');
    });

    testWidgets('a desktop browser window gets a dialog', (tester) async {
      api.on('GET', '/api/v1/nasabah', json: nasabahPage([]));
      await open(tester, const Size(1280, 800));

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('one pixel below medium is still a sheet', (tester) async {
      api.on('GET', '/api/v1/nasabah', json: nasabahPage([]));
      await open(
          tester, const Size(LayoutBreakpoint.mediumMinWidth - 1, 800));

      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('exactly medium is already a dialog', (tester) async {
      api.on('GET', '/api/v1/nasabah', json: nasabahPage([]));
      await open(tester, const Size(LayoutBreakpoint.mediumMinWidth, 800));

      expect(find.byType(Dialog), findsOneWidget);
    });
  });

  group('the dialog does the same job as the sheet', () {
    testWidgets('the list is shown and picking reports the nasabah',
        (tester) async {
      api.on('GET', '/api/v1/nasabah',
          json: nasabahPage([
            nasabahRow('1', nama: 'Budi Santoso'),
            nasabahRow('2', nama: 'Siti Aminah', saldo: '1500'),
          ]));
      await open(tester, const Size(1280, 800));

      expect(find.text('Budi Santoso'), findsOneWidget);
      await tester.tap(find.text('Siti Aminah'));
      await tester.pumpAndSettle();

      expect(chosen?.id, '2',
          reason: 'changing the container must not change the outcome');
      expect(find.byType(Dialog), findsNothing,
          reason: 'picking closes the dialog');
    });

    testWidgets('search still filters inside the dialog', (tester) async {
      api.on('GET', '/api/v1/nasabah',
          json: nasabahPage([
            nasabahRow('1', nama: 'Budi Santoso'),
            nasabahRow('2', nama: 'Siti Aminah'),
          ]));
      await open(tester, const Size(1280, 800));

      await tester.enterText(find.byType(TextField), 'siti');
      await tester.pump();

      expect(find.text('Budi Santoso'), findsNothing);
      expect(find.text('Siti Aminah'), findsOneWidget);
    });

    testWidgets('a failed fetch shows the backend message in the dialog',
        (tester) async {
      api.on('GET', '/api/v1/nasabah',
          status: 403, json: {'error': 'Tidak diizinkan'});
      await open(tester, const Size(1280, 800));

      expect(find.text('Tidak diizinkan'), findsOneWidget,
          reason: 'the picker never falls back to an unscoped list when the '
              'server refuses');
    });

    testWidgets('the dialog does not span the whole window', (tester) async {
      api.on('GET', '/api/v1/nasabah', json: nasabahPage([]));
      await open(tester, const Size(1280, 800));

      final box = tester.getSize(find.byType(Dialog));
      expect(box.width, lessThan(1280),
          reason: 'a dialog is centred and bounded, not a full-width band');
      expect(box.height, lessThan(800));
    });
  });
}
