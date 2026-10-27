import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/nasabah/presentation/pages/nasabah_page.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';

import '../../../../support/nasabah_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

const _path = '/api/v1/nasabah';

void main() {
  for (final layout in [
    (name: 'phone', size: const Size(590, 1000), isWeb: false),
    (name: 'web', size: const Size(1280, 900), isWeb: true),
  ]) {
    testWidgets('opening ${layout.name} search explains the searchable fields',
        (tester) async {
      final api = StubApi()..on('GET', _path, json: nasabahPage([]));
      await pumpRouted(
        tester,
        NasabahPage(isWeb: layout.isWeb),
        wrap: (app) => withNasabahProvider(buildNasabahNotifier(api), app),
        size: layout.size,
      );
      await tester.pumpAndSettle();

      expect(find.text('Cari nama, ID, atau nomor HP...'), findsOneWidget);
    });

    testWidgets(
        'typing and clearing an ID in ${layout.name} searches the server',
        (tester) async {
      final api = StubApi()
        ..on('GET', _path, json: nasabahPage([nasabahRow('1')]));
      final notifier = buildNasabahNotifier(api);
      await pumpRouted(
        tester,
        NasabahPage(isWeb: layout.isWeb),
        wrap: (app) => withNasabahProvider(notifier, app),
        size: layout.size,
      );
      await tester.pumpAndSettle();

      for (final query in ['NAS-000123', '000123']) {
        api.on('GET', _path,
            json: nasabahPage([nasabahRow('000123', nama: 'Siti Aminah')]));
        await tester.enterText(find.byType(TextField).first, query);
        await tester.pump(NasabahNotifier.jedaPencarian * 2);
        await tester.pumpAndSettle();

        expect(api.last.query['search'], query);
        expect(find.text('Siti Aminah'), findsOneWidget);
        expect(
          find.byWidgetPredicate((widget) =>
              widget is Text &&
              widget.data == (layout.isWeb ? 'NAS-000123' : 'ID: NAS-000123')),
          findsOneWidget,
        );
        expect(find.text('Budi Santoso'), findsNothing);
      }

      api.on('GET', _path, json: nasabahPage([]));
      await tester.enterText(find.byType(TextField).first, 'UNKNOWN-ID');
      await tester.pump(NasabahNotifier.jedaPencarian * 2);
      await tester.pumpAndSettle();
      expect(find.text('Nasabah Tidak Ditemukan'), findsOneWidget);

      api.on('GET', _path, json: nasabahPage([nasabahRow('1')]));
      await tester.enterText(find.byType(TextField).first, '');
      await tester.pump(NasabahNotifier.jedaPencarian * 2);
      await tester.pumpAndSettle();
      expect(api.last.query.containsKey('search'), isFalse);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Nasabah Tidak Ditemukan'), findsNothing);
    });
  }
}
