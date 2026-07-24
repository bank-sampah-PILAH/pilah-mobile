import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/profile/presentation/widgets/wa_variable_chips.dart';

/// The variable list exactly as the deployed backend returns it — note it does
/// not yet advertise `{daftar_item_harga}`.
const _backendVariables = ['{Nama}', '{Total}', '{Saldo}', '{Tanggal}', '{daftar_item}'];

void main() {
  group('WaVariableChips.withDaftarItemHarga', () {
    test('inserts {daftar_item_harga} right after {daftar_item}', () {
      expect(
        WaVariableChips.withDaftarItemHarga(_backendVariables),
        ['{Nama}', '{Total}', '{Saldo}', '{Tanggal}', '{daftar_item}', '{daftar_item_harga}'],
      );
    });

    test('does not duplicate an already-present {daftar_item_harga}', () {
      const source = ['{daftar_item}', '{daftar_item_harga}'];
      expect(WaVariableChips.withDaftarItemHarga(source), source);
    });

    test('appends when {daftar_item} is absent', () {
      expect(
        WaVariableChips.withDaftarItemHarga(const ['{Nama}']),
        ['{Nama}', '{daftar_item_harga}'],
      );
    });
  });

  group('WaVariableChips widget', () {
    Widget host({
      List<String> variables = _backendVariables,
      required ValueChanged<String> onInsert,
    }) =>
        MaterialApp(
          home: Scaffold(
            body: WaVariableChips(variables: variables, onInsert: onInsert),
          ),
        );

    testWidgets('renders a chip for the new {daftar_item_harga} variable even '
        'though the backend list omits it', (tester) async {
      await tester.pumpWidget(host(onInsert: (_) {}));

      expect(find.text('{daftar_item}'), findsOneWidget);
      expect(find.text('{daftar_item_harga}'), findsOneWidget);
    });

    testWidgets('tapping the {daftar_item_harga} chip reports the inserted token',
        (tester) async {
      String? inserted;
      await tester.pumpWidget(host(onInsert: (v) => inserted = v));

      await tester.tap(find.text('{daftar_item_harga}'));
      await tester.pump();

      expect(inserted, '{daftar_item_harga}');
    });

    testWidgets('each item-list variable carries a distinguishing description',
        (tester) async {
      await tester.pumpWidget(host(onInsert: (_) {}));

      Tooltip tooltipFor(String token) => tester.widget<Tooltip>(
            find.ancestor(of: find.text(token), matching: find.byType(Tooltip)),
          );

      expect(tooltipFor('{daftar_item}').message, 'Daftar item & berat');
      expect(tooltipFor('{daftar_item_harga}').message, 'Daftar item, berat, & harga');
    });
  });
}
