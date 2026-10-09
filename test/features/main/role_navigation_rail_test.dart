import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_navigation_rail.dart';

import '../../support/pump_app.dart';

/// The wide-window counterpart of RoleNavigationBar. It must offer exactly the
/// destinations the shared source gives it, in the same order, and report the
/// same menu index back — otherwise a Pengurus would land on a different
/// screen depending on how wide their browser happens to be.
void main() {
  Future<List<int>> taps(
    WidgetTester tester, {
    required String? role,
    int currentIndex = 0,
    Size window = const Size(1440, 900),
    bool limitedNasabah = false,
  }) async {
    final tapped = <int>[];
    await pumpRouted(
      tester,
      Scaffold(
        body: Row(children: [
          RoleNavigationRail(
            role: role,
            currentIndex: currentIndex,
            limitedNasabah: limitedNasabah,
            onSelected: tapped.add,
          ),
          const Expanded(child: SizedBox.shrink()),
        ]),
      ),
      size: window,
    );
    return tapped;
  }

  group('RoleNavigationRail', () {
    testWidgets('offers the five staff destinations as rail destinations',
        (tester) async {
      await taps(tester, role: 'pengelola');
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.destinations.length, 5);
      expect(
        rail.destinations.map((d) => (d.label as Text).data),
        ['Dashboard', 'Nasabah', 'Harga', 'Laporan', 'Jadwal'],
      );
    });

    testWidgets('marks the current destination as selected', (tester) async {
      await taps(tester, role: 'pengelola', currentIndex: 2);
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, 2);
    });

    testWidgets('reports the menu index that was tapped', (tester) async {
      final tapped = await taps(tester, role: 'pengelola');
      await tester.tap(find.text('Laporan'));
      await tester.pumpAndSettle();
      expect(tapped, [3], reason: 'Laporan is menu index 3, not branch index');
    });

    testWidgets('shows labels beside icons on a desktop window',
        (tester) async {
      await taps(tester, role: 'pengelola', window: const Size(1440, 900));
      expect(
          tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
          isTrue);
    });

    testWidgets('keeps the rail narrow on a tablet window', (tester) async {
      await taps(tester, role: 'pengelola', window: const Size(720, 900));
      expect(
          tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
          isFalse,
          reason: 'a tablet cannot spare the width for extended labels');
    });

    testWidgets('the collapsed rail still names its destinations',
        (tester) async {
      await taps(tester, role: 'pengelola', window: const Size(720, 900));
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isFalse);
      expect(rail.labelType, NavigationRailLabelType.all,
          reason: 'five unlabelled icons with no tooltip are a guessing game');
    });

    testWidgets('the extended rail does not repeat labels underneath',
        (tester) async {
      await taps(tester, role: 'pengelola', window: const Size(1440, 900));
      expect(
          tester.widget<NavigationRail>(find.byType(NavigationRail)).labelType,
          NavigationRailLabelType.none,
          reason: 'Material asserts on any other value while extended');
    });

    testWidgets('renders nothing at all for a role without navigation',
        (tester) async {
      await taps(tester, role: 'superadmin');
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('renders nothing when there is no session', (tester) async {
      await taps(tester, role: null);
      expect(find.byType(NavigationRail), findsNothing);
    });
  });
}
