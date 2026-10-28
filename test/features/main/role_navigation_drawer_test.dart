import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_navigation_config.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_navigation_drawer.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_transaction_menu.dart';

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
    bool transactionSelected = false,
    VoidCallback? onAddTransaction,
  }) async {
    final selected = <int>[];
    await pumpRouted(
      tester,
      Scaffold(
        body: RoleNavigationDrawer(
          navigation: RoleNavigationConfig(
            role: role,
            currentIndex: currentIndex,
            bankSampahNama: bankSampahNama,
            limitedNasabah: limitedNasabah,
            transactionSelected: transactionSelected,
            onSelected: selected.add,
            onAddTransaction: onAddTransaction,
          ),
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
        'Aktivitas',
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

    testWidgets('shows the expanded Transaksi menu before destinations',
        (tester) async {
      var added = false;
      await mountDrawer(tester, onAddTransaction: () => added = true);

      expect(find.text('Transaksi'), findsOneWidget);
      expect(find.text('Setoran'), findsOneWidget);
      expect(find.text('Pencairan'), findsOneWidget);
      expect(find.text('Tambah Transaksi'), findsNothing);
      expect(
        tester.getTopLeft(find.text('Transaksi')).dy,
        lessThan(tester.getTopLeft(find.text('Dashboard')).dy),
      );
      final pencairan = tester
          .widget<RoleMenuRow>(find.byKey(RoleTransactionMenu.pencairanKey));
      expect(pencairan.enabled, isFalse);
      expect(pencairan.onTap, isNull);

      await tester.tap(find.byKey(RoleTransactionMenu.setoranKey));
      await tester.pumpAndSettle();
      expect(added, isTrue);
    });

    testWidgets('highlights Transaksi and Setoran on the Setoran page',
        (tester) async {
      await mountDrawer(tester,
          transactionSelected: true, onAddTransaction: () {});

      expect(
        tester
            .widget<RoleMenuRow>(find.byKey(RoleTransactionMenu.headerKey))
            .selected,
        isTrue,
      );
      final setoran = tester
          .widget<RoleMenuRow>(find.byKey(RoleTransactionMenu.setoranKey));
      expect(setoran.selected, isTrue);
      expect(
        tester.widget<Text>(find.text('Setoran')).style?.color,
        AppColors.greenDark,
      );
    });

    testWidgets('hides the transaction menu from Pengelola Induk',
        (tester) async {
      await mountDrawer(
        tester,
        role: 'pengelola_induk',
        onAddTransaction: () {},
      );

      expect(find.text('Transaksi'), findsNothing);
    });

    testWidgets('reports the menu index that was tapped', (tester) async {
      final selected = await mountDrawer(tester);
      await tester.tap(find.text('Harga'));
      await tester.pumpAndSettle();
      expect(selected, [2],
          reason: 'the index is the menu position, not the branch index');
    });

    testWidgets('keeps Pengumuman visible but disabled', (tester) async {
      final selected = await mountDrawer(tester);
      final destinationFinder =
          find.byKey(RoleNavigationDrawer.destinationKey(5));
      final destination =
          tester.getSemantics(destinationFinder).getSemanticsData();

      expect(find.text('Pengumuman'), findsOneWidget);
      expect(destination.flagsCollection.isEnabled, Tristate.isFalse);
      expect(destination.hasAction(SemanticsAction.tap), isFalse);
      final disabledIcon = tester.widget<Icon>(find.descendant(
        of: destinationFinder,
        matching: find.byType(Icon),
      ));
      final disabledLabel = tester.widget<Text>(find.descendant(
        of: destinationFinder,
        matching: find.text('Pengumuman'),
      ));
      final disabledIconContainer = tester.widget<Container>(find.descendant(
        of: destinationFinder,
        matching: find.byType(Container),
      ));
      expect(disabledIcon.color, AppColors.grey100);
      expect(disabledLabel.style?.color, AppColors.grey100);
      expect(
        (disabledIconContainer.decoration as BoxDecoration).color,
        isNull,
      );

      await tester.tap(find.text('Pengumuman'));
      await tester.pumpAndSettle();
      expect(selected, isEmpty);
    });

    testWidgets('marks the current destination as selected', (tester) async {
      await mountDrawer(tester, currentIndex: 3);
      final selected = tester
          .getSemantics(find.byKey(RoleNavigationDrawer.destinationKey(3)))
          .getSemanticsData()
          .flagsCollection
          .isSelected;
      expect(selected, Tristate.isTrue);

      final selectedFinder = find.byKey(RoleNavigationDrawer.destinationKey(3));
      final selectedIcon = tester.widget<Icon>(find.descendant(
        of: selectedFinder,
        matching: find.byType(Icon),
      ));
      final selectedLabel = tester.widget<Text>(find.descendant(
        of: selectedFinder,
        matching: find.text('Aktivitas'),
      ));
      final selectedIconContainer = tester.widget<Container>(find.descendant(
        of: selectedFinder,
        matching: find.byType(Container),
      ));
      expect(selectedIcon.color, AppColors.greenDark);
      expect(selectedLabel.style?.color, AppColors.greenDark);
      expect(selectedLabel.style?.fontWeight, FontWeight.w600);
      expect(
        (selectedIconContainer.decoration as BoxDecoration).color,
        AppColors.greenLight,
      );

      final idleFinder = find.byKey(RoleNavigationDrawer.destinationKey(0));
      final idleIcon = tester.widget<Icon>(find.descendant(
        of: idleFinder,
        matching: find.byType(Icon),
      ));
      final idleLabel = tester.widget<Text>(find.descendant(
        of: idleFinder,
        matching: find.text('Dashboard'),
      ));
      expect(idleIcon.color, AppColors.inkSoft);
      expect(idleLabel.style?.color, AppColors.inkSoft);
      expect(idleLabel.style?.fontWeight, FontWeight.w500);
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
      expect(find.byType(Drawer), findsNothing,
          reason: 'an unknown role fails closed, as it does on the rail');
    });

    testWidgets('no session gets nothing at all', (tester) async {
      await mountDrawer(tester, role: '');
      expect(find.byType(Drawer), findsNothing);
    });
  });

  group('RoleNavigationDrawer inside a Scaffold', () {
    testWidgets('choosing Setoran closes the drawer and opens the form',
        (tester) async {
      var added = false;
      await pumpRouted(
        tester,
        Scaffold(
          drawer: RoleNavigationDrawer(
            navigation: RoleNavigationConfig(
              role: 'pengelola',
              currentIndex: 0,
              bankSampahNama: 'Bank Sampah Melati',
              onSelected: (_) {},
              onAddTransaction: () => added = true,
            ),
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
      await tester.tap(find.byKey(RoleTransactionMenu.setoranKey));
      await tester.pumpAndSettle();

      expect(added, isTrue);
      expect(find.text('Transaksi'), findsNothing);
    });

    testWidgets('choosing a destination closes the drawer', (tester) async {
      final selected = <int>[];
      await pumpRouted(
        tester,
        Scaffold(
          drawer: RoleNavigationDrawer(
            navigation: RoleNavigationConfig(
              role: 'pengelola',
              currentIndex: 0,
              bankSampahNama: 'Bank Sampah Melati',
              onSelected: selected.add,
            ),
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
      expect(find.text('Aktivitas'), findsOneWidget);

      await tester.tap(find.text('Aktivitas'));
      await tester.pumpAndSettle();

      expect(selected, [3]);
      expect(find.text('Aktivitas'), findsNothing,
          reason: 'a drawer that stays open hides the page it just opened');
    });
  });

  group('RoleNavigationDrawer: Riwayat in the Transaksi accordion', () {
    testWidgets('moves Aktivitas under Transaksi as Riwayat for a pengurus',
        (tester) async {
      await mountDrawer(tester, onAddTransaction: () {});

      expect(find.text('Aktivitas'), findsNothing);
      expect(find.byKey(RoleTransactionMenu.riwayatKey), findsOneWidget);
      expect(find.text('Riwayat'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Riwayat')).dy,
        lessThan(tester.getTopLeft(find.text('Setoran')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Pencairan')).dy,
        lessThan(tester.getTopLeft(find.text('Dashboard')).dy),
      );
    });

    testWidgets('tapping Riwayat reports the Aktivitas menu index',
        (tester) async {
      final selected = await mountDrawer(tester, onAddTransaction: () {});

      await tester.tap(find.byKey(RoleTransactionMenu.riwayatKey));
      await tester.pumpAndSettle();

      expect(selected, [3]);
    });

    testWidgets('the destinations after it keep their menu index',
        (tester) async {
      final selected = await mountDrawer(tester, onAddTransaction: () {});

      await tester.tap(find.text('Jadwal'));
      await tester.pumpAndSettle();

      expect(selected, [4]);
    });

    testWidgets('on the history page Riwayat is the selected entry',
        (tester) async {
      await mountDrawer(tester, currentIndex: 3, onAddTransaction: () {});

      expect(
        tester
            .widget<RoleMenuRow>(find.byKey(RoleTransactionMenu.riwayatKey))
            .selected,
        isTrue,
      );
    });

    testWidgets('Pengelola Induk keeps Aktivitas', (tester) async {
      await mountDrawer(tester,
          role: 'pengelola_induk', onAddTransaction: () {});

      expect(find.text('Aktivitas'), findsOneWidget);
      expect(find.text('Riwayat'), findsNothing);
    });
  });
}
