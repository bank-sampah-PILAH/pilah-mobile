import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/nasabah/presentation/pages/nasabah_page.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';

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

  for (final layout in [
    (name: 'native phone', size: const Size(390, 844), web: false),
    (name: 'web phone', size: const Size(390, 844), web: true),
    (name: 'web desktop', size: const Size(1280, 900), web: true),
  ]) {
    testWidgets('${layout.name} shows default order and hides reset',
        (tester) async {
      await open(tester, size: layout.size, isWeb: layout.web);

      expect(find.byKey(_orderKey), findsOneWidget);
      expect(find.text('Nomor'), findsOneWidget);
      expect(find.text('Atur ulang'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '${layout.name} selects every order and keeps its label visible',
        (tester) async {
      await open(tester, size: layout.size, isWeb: layout.web);

      for (final choice in [
        ('Nama A–Z', 'nama'),
        ('Terbaru bergabung', 'terbaru'),
        ('Saldo terbesar', 'saldo_terbesar'),
        ('Saldo terkecil', 'saldo_terkecil'),
        ('Nomor', 'nomor'),
      ]) {
        await tester.tap(find.byKey(_orderKey));
        await tester.pumpAndSettle();
        await tester.tap(find.text(choice.$1).last);
        await tester.pumpAndSettle();

        expect(api.last.query['urutan'], choice.$2);
        expect(find.text(choice.$1), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  }
}
