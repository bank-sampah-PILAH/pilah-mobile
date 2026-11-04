import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/nasabah/presentation/pages/nasabah_page.dart';

import '../../../../support/nasabah_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

const _path = '/api/v1/nasabah';

void main() {
  for (final layout in [
    (name: 'phone', size: const Size(590, 1000), isWeb: false),
    (name: 'web', size: const Size(1280, 900), isWeb: true),
  ]) {
    testWidgets('the ${layout.name} search hint names the searchable fields',
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
  }
}
