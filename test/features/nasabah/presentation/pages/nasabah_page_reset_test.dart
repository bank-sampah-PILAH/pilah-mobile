import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/nasabah/presentation/pages/nasabah_page.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';
import 'package:pilah_mobile/features/nasabah/presentation/states/nasabah_state.dart';

import '../../../../support/nasabah_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

const _path = '/api/v1/nasabah';
const _orderKey = ValueKey('nasabah-order');

void main() {
  late StubApi api;
  late NasabahNotifier notifier;

  setUp(() {
    api = StubApi();
    notifier = buildNasabahNotifier(api);
    api.on('GET', _path, json: nasabahPage([nasabahRow('1')]));
  });

  Future<void> open(WidgetTester tester,
      {required Size size, required bool isWeb}) async {
    await pumpRouted(
      tester,
      NasabahPage(isWeb: isWeb),
      wrap: (app) => withNasabahProvider(notifier, app),
      size: size,
    );
    await tester.pumpAndSettle();
  }

  Future<void> selectOrder(WidgetTester tester, String label) async {
    await tester.tap(find.byKey(_orderKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  for (final layout in [
    (name: 'native phone', size: const Size(390, 844), web: false),
    (name: 'web phone', size: const Size(390, 844), web: true),
    (name: 'web desktop', size: const Size(1280, 900), web: true),
  ]) {
    for (final tab in [
      ('Aktif', 'aktif'),
      ('Tidak Aktif', 'tidak_aktif'),
      ('Menunggu', 'menunggu'),
    ]) {
      testWidgets('${layout.name} resets only search and order on ${tab.$1}',
          (tester) async {
        await open(tester, size: layout.size, isWeb: layout.web);
        await tester.ensureVisible(find.text(tab.$1).first);
        await tester.tap(find.text(tab.$1).first);
        await tester.pumpAndSettle();
        expect(find.text('Atur ulang'), findsNothing,
            reason: 'A non-default status alone must not show reset');

        for (final filters in [
          (search: true, sort: false),
          (search: false, sort: true),
          (search: true, sort: true),
        ]) {
          if (filters.sort) await selectOrder(tester, 'Saldo terbesar');
          if (filters.search) {
            await tester.enterText(find.byType(TextField), 'Budi');
            await tester.pump(NasabahNotifier.jedaPencarian * 2);
            await tester.pumpAndSettle();
          }
          expect(find.text('Atur ulang'), findsOneWidget);

          await tester.tap(find.text('Atur ulang'));
          await tester.pumpAndSettle();

          expect(api.last.query['status'], tab.$2);
          expect(api.last.query['urutan'], 'nomor');
          expect(api.last.query['page'], '1');
          expect(api.last.query.containsKey('search'), isFalse);
          expect(
              tester.widget<TextField>(find.byType(TextField)).controller!.text,
              isEmpty);
          expect(find.text('Nomor'), findsOneWidget);
          expect(find.text('Atur ulang'), findsNothing);
          expect(tester.takeException(), isNull);
        }
      });
    }

    testWidgets('${layout.name} can reset an empty search result',
        (tester) async {
      await open(tester, size: layout.size, isWeb: layout.web);
      api.on('GET', _path, json: nasabahPage([]));
      await tester.enterText(find.byType(TextField), 'Tidak ada');
      await tester.pump(NasabahNotifier.jedaPencarian * 2);
      await tester.pumpAndSettle();
      expect(find.text('Nasabah Tidak Ditemukan'), findsOneWidget);

      api.on('GET', _path, json: nasabahPage([nasabahRow('1')]));
      await tester.tap(find.text('Atur ulang'));
      await tester.pumpAndSettle();
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Atur ulang'), findsNothing);
    });

    testWidgets('${layout.name} exposes reset while a search is debouncing',
        (tester) async {
      await open(tester, size: layout.size, isWeb: layout.web);
      await tester.enterText(find.byType(TextField), 'Budi');
      await tester.pump();
      expect(find.text('Atur ulang'), findsOneWidget);
      await tester.tap(find.text('Atur ulang'));
      await tester.pumpAndSettle();
      await tester.pump(NasabahNotifier.jedaPencarian * 2);
      await tester.pumpAndSettle();

      expect(api.last.query.containsKey('search'), isFalse);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
          isEmpty);
      expect(find.text('Atur ulang'), findsNothing);
    });

    testWidgets('${layout.name} keeps controls available after load failure',
        (tester) async {
      await open(tester, size: layout.size, isWeb: layout.web);
      api.on('GET', _path, status: 500, json: {});
      await selectOrder(tester, 'Saldo terkecil');
      expect(notifier.state, isA<NasabahError>());
      expect(find.text('Saldo terkecil'), findsOneWidget);
      expect(find.text('Atur ulang'), findsOneWidget);

      api.on('GET', _path, json: nasabahPage([nasabahRow('1')]));
      await tester.tap(find.text('Atur ulang'));
      await tester.pumpAndSettle();
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Atur ulang'), findsNothing);
    });
  }

  testWidgets('search and reset stay synchronized when the web layout resizes',
      (tester) async {
    await open(tester, size: const Size(1280, 900), isWeb: true);
    await tester.enterText(find.byType(TextField), 'Budi');
    await tester.pump(NasabahNotifier.jedaPencarian * 2);
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Budi');
    await tester.tap(find.text('Atur ulang'));
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(1280, 900);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty);
    expect(find.text('Atur ulang'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
