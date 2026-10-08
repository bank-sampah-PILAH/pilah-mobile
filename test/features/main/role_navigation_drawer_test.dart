import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_navigation_drawer.dart';

import '../../support/pump_app.dart';

/// A browser window narrower than 600 cannot show a 256px rail and the content
/// at the same time, but the lead dev's rule is that a browser keeps its
/// navigation on the left. So on a phone browser the destinations move behind a
/// menu button and open as a drawer from the left edge.
///
/// The destinations themselves are still decided by role, from the same source
/// the bottom bar and the rail read.
void main() {
  Future<List<int>> mountDrawer(
    WidgetTester tester, {
    String role = 'pengelola',
    int currentIndex = 0,
    String? bankSampahNama = 'Bank Sampah Melati',
    bool limitedNasabah = false,
  }) async {
    final selected = <int>[];
    await pumpRouted(
      tester,
      Scaffold(
        body: RoleNavigationDrawer(
          role: role,
          currentIndex: currentIndex,
          bankSampahNama: bankSampahNama,
          limitedNasabah: limitedNasabah,
          onSelected: selected.add,
        ),
      ),
      size: const Size(390, 844),
    );
    return selected;
  }

  group('RoleNavigationDrawer', () {
    testWidgets('lists the staff destinations by name', (tester) async {
      await mountDrawer(tester);
      for (final label in [
        'Dashboard',
        'Nasabah',
        'Harga',
        'Laporan',
        'Jadwal'
      ]) {
        expect(find.text(label), findsOneWidget,
            reason: 'a drawer has room for labels, so it must use them');
      }
    });

    testWidgets('names the bank sampah being managed', (tester) async {
      await mountDrawer(tester);
      expect(find.text('Bank Sampah Melati'), findsOneWidget);
    });

    testWidgets('reports the menu index that was tapped', (tester) async {
      final selected = await mountDrawer(tester);
      await tester.tap(find.text('Harga'));
      await tester.pumpAndSettle();
      expect(selected, [2],
          reason: 'the index is the menu position, not the branch index');
    });

    testWidgets('marks the current destination as selected', (tester) async {
      await mountDrawer(tester, currentIndex: 3);
      final drawer =
          tester.widget<NavigationDrawer>(find.byType(NavigationDrawer));
      expect(drawer.selectedIndex, 3);
    });

    testWidgets('an unapproved nasabah only sees their two destinations',
        (tester) async {
      await mountDrawer(tester, role: 'nasabah', limitedNasabah: true);
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
      expect(find.text('Nasabah'), findsNothing,
          reason: 'the staff menu must never leak into a nasabah drawer');
    });

    testWidgets('a role without navigation gets nothing at all',
        (tester) async {
      await mountDrawer(tester, role: 'satpam');
      expect(find.byType(NavigationDrawer), findsNothing,
          reason: 'an unknown role fails closed, as it does on the rail');
    });

    testWidgets('no session gets nothing at all', (tester) async {
      await mountDrawer(tester, role: '');
      expect(find.byType(NavigationDrawer), findsNothing);
    });
  });

  group('RoleNavigationDrawer inside a Scaffold', () {
    testWidgets('choosing a destination closes the drawer', (tester) async {
      final selected = <int>[];
      await pumpRouted(
        tester,
        Scaffold(
          drawer: RoleNavigationDrawer(
            role: 'pengelola',
            currentIndex: 0,
            bankSampahNama: 'Bank Sampah Melati',
            onSelected: selected.add,
          ),
          body: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: Scaffold.of(context).openDrawer,
            ),
          ),
        ),
        size: const Size(390, 844),
      );

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(find.text('Laporan'), findsOneWidget);

      await tester.tap(find.text('Laporan'));
      await tester.pumpAndSettle();

      expect(selected, [3]);
      expect(find.text('Laporan'), findsNothing,
          reason: 'a drawer that stays open hides the page it just opened');
    });
  });
}
