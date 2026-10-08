import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_navigation_rail.dart';

import '../../support/pump_app.dart';

/// A browser user navigates with Tab and Enter, which a phone user never does.
/// The rail is the first thing on every page, so it has to be reachable and
/// operable from the keyboard alone.
void main() {
  Future<List<int>> mount(WidgetTester tester) async {
    final selected = <int>[];
    await pumpRouted(
      tester,
      Scaffold(
        body: Row(children: [
          RoleNavigationRail(
            role: 'pengelola',
            currentIndex: 0,
            bankSampahNama: 'Bank Sampah Melati',
            onSelected: selected.add,
          ),
          const Expanded(child: SizedBox.shrink()),
        ]),
      ),
      size: const Size(1440, 900),
    );
    return selected;
  }

  group('RoleNavigationRail keyboard access', () {
    testWidgets('the first Tab lands on the first destination', (tester) async {
      final selected = await mount(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(selected, [0],
          reason: 'Tab should enter the rail at the top, not skip past it');
    });

    testWidgets('Enter activates the focused destination', (tester) async {
      final selected = await mount(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(selected, isNotEmpty,
          reason:
              'a keyboard user must be able to change page without a mouse');
    });

    testWidgets('every destination is reachable by repeated Tab',
        (tester) async {
      final selected = await mount(tester);
      // Five destinations: tab onto each in turn and activate it.
      for (var i = 0; i < 5; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
      }
      expect(selected.toSet().length, 5,
          reason: 'Tab must not cycle within one destination');
    });
  });
}
