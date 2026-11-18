import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/analytics/replay_masks.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_navigation_bar.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_navigation_config.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_navigation_drawer.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_navigation_rail.dart';

import '../../support/pump_app.dart';

/// The navigation is fixed wording of the app, so the screen recording shows
/// it. What belongs to a pengurus (the name and email in the footer) stays
/// hidden, which is why each label is wrapped one by one.
void main() {
  Finder revealed(Finder text) => find.ancestor(
        of: text,
        matching: find.byType(RevealInReplay),
      );

  RoleNavigationConfig config() => RoleNavigationConfig(
        role: 'pengelola',
        currentIndex: 0,
        profileName: 'Budi Santoso',
        profileEmail: 'budi@example.test',
        onSelected: (_) {},
        onAddTransaction: () {},
      );

  group('the rail', () {
    Future<void> pumpRail(WidgetTester tester) => pumpRouted(
          tester,
          Scaffold(
            body: Row(children: [
              RoleNavigationRail(navigation: config()),
              const Expanded(child: SizedBox.shrink()),
            ]),
          ),
          size: const Size(1440, 900),
        );

    testWidgets('shows its destination labels and captions', (tester) async {
      await pumpRail(tester);

      for (final label in ['Dashboard', 'Nasabah', 'Harga', 'Jadwal', 'MENU']) {
        expect(revealed(find.text(label)), findsOneWidget, reason: label);
      }
      expect(revealed(find.text('PILAH')), findsOneWidget);
    });

    testWidgets('shows the Transaksi menu', (tester) async {
      await pumpRail(tester);

      for (final label in ['Transaksi', 'Riwayat', 'Setoran']) {
        expect(revealed(find.text(label)), findsOneWidget, reason: label);
      }
    });

    testWidgets('keeps the name and email of the pengurus hidden',
        (tester) async {
      await pumpRail(tester);

      expect(revealed(find.text('Budi Santoso')), findsNothing);
      expect(revealed(find.text('budi@example.test')), findsNothing);
    });
  });

  testWidgets('the drawer shows its labels and keeps the profile hidden',
      (tester) async {
    await pumpRouted(
      tester,
      Scaffold(body: RoleNavigationDrawer(navigation: config())),
      size: const Size(390, 844),
    );

    for (final label in ['Dashboard', 'Nasabah', 'Harga', 'Jadwal', 'MENU']) {
      expect(revealed(find.text(label)), findsOneWidget, reason: label);
    }
    expect(revealed(find.text('Budi Santoso')), findsNothing);
  });

  testWidgets('the bottom bar is shown in the screen recording',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        bottomNavigationBar: RoleNavigationBar(
          role: 'pengelola',
          currentIndex: 0,
          onSelected: (_) {},
        ),
      ),
    ));

    expect(
      find.ancestor(
        of: find.byType(BottomNavigationBar),
        matching: find.byType(RevealInReplay),
      ),
      findsOneWidget,
    );
  });
}
