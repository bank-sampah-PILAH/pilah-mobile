import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_navigation_config.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_navigation_rail.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_transaction_menu.dart';

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
    bool transactionSelected = false,
    VoidCallback? onAddTransaction,
  }) async {
    final tapped = <int>[];
    await pumpRouted(
      tester,
      Scaffold(
        body: Row(children: [
          RoleNavigationRail(
            navigation: RoleNavigationConfig(
              role: role,
              currentIndex: currentIndex,
              limitedNasabah: limitedNasabah,
              transactionSelected: transactionSelected,
              onSelected: tapped.add,
              onAddTransaction: onAddTransaction,
            ),
          ),
          const Expanded(child: SizedBox.shrink()),
        ]),
      ),
      size: window,
    );
    return tapped;
  }

  group('RoleNavigationRail', () {
    testWidgets('offers the five staff destinations', (tester) async {
      await taps(tester, role: 'pengelola');
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.destinations.length, 5);
      const expectedLabels = [
        'Dashboard',
        'Nasabah',
        'Harga',
        'Aktivitas',
        'Jadwal',
      ];
      final visibleLabels = tester
          .widgetList<Text>(find.byType(Text))
          .map((label) => label.data)
          .where(expectedLabels.contains)
          .toList();
      expect(visibleLabels, expectedLabels);
    });

    testWidgets('draws no Pengumuman destination at all', (tester) async {
      await taps(tester, role: 'pengelola');
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));

      expect(find.text('Pengumuman'), findsNothing);
      expect(
        rail.destinations.map((d) => (d.label as Text).data),
        isNot(contains('Pengumuman')),
      );
      expect(find.byIcon(Icons.campaign_outlined), findsNothing);
    });

    testWidgets('shows the Transaksi accordion before destinations',
        (tester) async {
      var added = false;
      await taps(tester,
          role: 'pengelola', onAddTransaction: () => added = true);

      expect(find.text('Transaksi'), findsOneWidget);
      expect(find.text('Setoran'), findsOneWidget);
      expect(find.text('Pencairan'), findsNothing);
      expect(find.text('Tambah Transaksi'), findsNothing);
      expect(
        tester
            .widget<RoleMenuRow>(find.byKey(RoleTransactionMenu.headerKey))
            .selected,
        isFalse,
      );
      expect(
        tester.widget<Text>(find.text('Transaksi')).style?.color,
        AppColors.inkSoft,
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.receipt_long_outlined)).color,
        AppColors.inkSoft,
      );
      expect(
        tester.getTopLeft(find.text('Transaksi')).dy,
        lessThan(tester.getTopLeft(find.text('Dashboard')).dy),
      );
      final setoran = tester
          .widget<RoleMenuRow>(find.byKey(RoleTransactionMenu.setoranKey));
      expect(setoran.selected, isFalse);
      expect(
        tester.widget<Text>(find.text('Setoran')).style?.color,
        AppColors.inkSoft,
      );
      await tester.tap(find.byKey(RoleTransactionMenu.setoranKey));
      await tester.pumpAndSettle();
      expect(added, isTrue);
    });

    testWidgets('highlights both transaction entries only on Setoran',
        (tester) async {
      await taps(
        tester,
        role: 'pengelola',
        transactionSelected: true,
        onAddTransaction: () {},
      );

      expect(
        tester
            .widget<RoleMenuRow>(find.byKey(RoleTransactionMenu.headerKey))
            .selected,
        isTrue,
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.receipt_long_outlined)).color,
        AppColors.greenDark,
      );
      expect(
        tester.widget<Text>(find.text('Transaksi')).style?.color,
        AppColors.greenDark,
      );
      final setoran = tester
          .widget<RoleMenuRow>(find.byKey(RoleTransactionMenu.setoranKey));
      expect(setoran.selected, isTrue);
      expect(
        tester.widget<Text>(find.text('Setoran')).style?.color,
        AppColors.greenDark,
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.add_circle_outline)).color,
        AppColors.greenDark,
      );
    });

    testWidgets('marks the collapsed transaction shortcut selected on Setoran',
        (tester) async {
      await taps(
        tester,
        role: 'pengelola',
        window: const Size(720, 900),
        transactionSelected: true,
        onAddTransaction: () {},
      );

      final shortcut =
          tester.widget<IconButton>(find.byKey(RoleTransactionMenu.menuKey));
      expect((shortcut.icon as Icon).color, AppColors.greenDark);
    });

    testWidgets('collapsed rail opens Setoran with one tap, without a menu',
        (tester) async {
      var added = false;
      await taps(
        tester,
        role: 'pengelola',
        window: const Size(720, 900),
        onAddTransaction: () => added = true,
      );

      await tester.tap(find.byKey(RoleTransactionMenu.menuKey));
      await tester.pumpAndSettle();

      expect(added, isTrue);
      // Setoran is the only transaction left open (PIL-434), and a menu with
      // one entry is a tap spent on a choice that is not a choice.
      expect(find.byType(PopupMenuButton<dynamic>), findsNothing);
      expect(find.byKey(RoleTransactionMenu.setoranKey), findsNothing);
    });

    testWidgets('the collapsed shortcut offers no Pencairan', (tester) async {
      await taps(
        tester,
        role: 'pengelola',
        window: const Size(720, 900),
        onAddTransaction: () {},
      );

      await tester.tap(find.byKey(RoleTransactionMenu.menuKey));
      await tester.pumpAndSettle();

      expect(find.text('Pencairan'), findsNothing);
      expect(find.byKey(RoleTransactionMenu.pencairanKey), findsNothing);
      expect(find.byIcon(Icons.payments_outlined), findsNothing);
    });

    testWidgets('the wide rail keeps Riwayat and Setoran, and nothing dead',
        (tester) async {
      var added = false;
      await taps(
        tester,
        role: 'pengelola',
        window: const Size(1440, 900),
        onAddTransaction: () => added = true,
      );

      expect(find.text('Transaksi'), findsOneWidget);
      expect(find.text('Riwayat'), findsOneWidget);
      expect(find.text('Setoran'), findsOneWidget);
      expect(find.text('Pencairan'), findsNothing);
      expect(find.byKey(RoleTransactionMenu.pencairanKey), findsNothing);

      // Every row drawn in the accordion can be used: none is inert.
      final rows = tester
          .widgetList<RoleMenuRow>(find.byType(RoleMenuRow))
          .where((row) => row.key != RoleTransactionMenu.headerKey);
      expect(rows, isNotEmpty);
      for (final row in rows) {
        expect(row.enabled, isTrue, reason: '${row.label} is a dead control');
      }

      await tester.tap(find.byKey(RoleTransactionMenu.setoranKey));
      await tester.pumpAndSettle();
      expect(added, isTrue);
    });

    testWidgets('marks the current destination as selected', (tester) async {
      await taps(tester, role: 'pengelola', currentIndex: 2);
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, 2);
    });

    testWidgets('reports the menu index that was tapped', (tester) async {
      final tapped = await taps(tester, role: 'pengelola');
      await tester.tap(find.text('Aktivitas'));
      await tester.pumpAndSettle();
      expect(tapped, [3],
          reason: 'Aktivitas is menu index 3, not branch index');
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

    testWidgets('hides the transaction menu from Pengelola Induk',
        (tester) async {
      await taps(
        tester,
        role: 'pengelola_induk',
        onAddTransaction: () {},
      );
      expect(find.text('Transaksi'), findsNothing);
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

  group('RoleNavigationRail: Riwayat in the Transaksi accordion', () {
    testWidgets('moves Aktivitas under Transaksi as Riwayat for a pengurus',
        (tester) async {
      await taps(tester, role: 'pengelola', onAddTransaction: () {});

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.destinations.length, 4);
      expect(
        rail.destinations.map((d) => (d.label as Text).data),
        ['Dashboard', 'Nasabah', 'Harga', 'Jadwal'],
      );
      expect(find.text('Aktivitas'), findsNothing);
      expect(find.byKey(RoleTransactionMenu.riwayatKey), findsOneWidget);
      expect(find.text('Riwayat'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Riwayat')).dy,
        lessThan(tester.getTopLeft(find.text('Setoran')).dy),
      );
    });

    testWidgets('tapping Riwayat reports the Aktivitas menu index',
        (tester) async {
      final selected =
          await taps(tester, role: 'pengelola', onAddTransaction: () {});

      await tester.tap(find.byKey(RoleTransactionMenu.riwayatKey));
      await tester.pumpAndSettle();

      expect(selected, [3]);
    });

    testWidgets('the destinations after it still report their own index',
        (tester) async {
      final selected =
          await taps(tester, role: 'pengelola', onAddTransaction: () {});

      await tester.tap(find.text('Jadwal'));
      await tester.pumpAndSettle();

      expect(selected, [4]);
    });

    testWidgets('on the history page Riwayat is selected, not a destination',
        (tester) async {
      await taps(tester,
          role: 'pengelola', currentIndex: 3, onAddTransaction: () {});

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, isNull);
      final riwayat = tester
          .widget<RoleMenuRow>(find.byKey(RoleTransactionMenu.riwayatKey));
      expect(riwayat.selected, isTrue);
    });

    testWidgets('a destination after it keeps its highlight', (tester) async {
      await taps(tester,
          role: 'pengelola', currentIndex: 4, onAddTransaction: () {});

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, 3, reason: 'Jadwal is the fourth entry now');
      expect(
        tester
            .widget<RoleMenuRow>(find.byKey(RoleTransactionMenu.riwayatKey))
            .selected,
        isFalse,
      );
    });

    testWidgets('the collapsed rail keeps Aktivitas as its own destination',
        (tester) async {
      await taps(tester,
          role: 'pengelola',
          window: const Size(720, 900),
          onAddTransaction: () {});

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.destinations.length, 5);
      expect(find.text('Aktivitas'), findsOneWidget);
    });

    testWidgets('Pengelola Induk keeps Aktivitas', (tester) async {
      await taps(tester, role: 'pengelola_induk', onAddTransaction: () {});

      expect(find.text('Aktivitas'), findsOneWidget);
      expect(find.text('Riwayat'), findsNothing);
    });
  });

  group('RoleNavigationRail: Transaksi rows look like the destinations', () {
    ShapeDecoration pillOf(WidgetTester tester, Key key) {
      final pill = find
          .descendant(of: find.byKey(key), matching: find.byType(Container))
          .first;
      return tester.widget<Container>(pill).decoration! as ShapeDecoration;
    }

    testWidgets('every row is at least 48dp tall to tap', (tester) async {
      await taps(tester, role: 'pengelola', onAddTransaction: () {});

      for (final key in [
        RoleTransactionMenu.headerKey,
        RoleTransactionMenu.riwayatKey,
        RoleTransactionMenu.setoranKey,
      ]) {
        expect(
          tester.getSize(find.byKey(key)).height,
          greaterThanOrEqualTo(kMinInteractiveDimension),
          reason: '$key',
        );
      }
    });

    testWidgets('each row keeps its icon in a 56x32 rounded pill',
        (tester) async {
      await taps(tester, role: 'pengelola', onAddTransaction: () {});

      for (final key in [
        RoleTransactionMenu.headerKey,
        RoleTransactionMenu.riwayatKey,
        RoleTransactionMenu.setoranKey,
      ]) {
        final pill = find
            .descendant(of: find.byKey(key), matching: find.byType(Container))
            .first;
        expect(tester.getSize(pill), const Size(56, 32), reason: '$key');
        expect(pillOf(tester, key).shape, isA<StadiumBorder>());
      }
    });

    testWidgets('the pill fills green only when selected', (tester) async {
      await taps(tester,
          role: 'pengelola', currentIndex: 3, onAddTransaction: () {});

      expect(
        pillOf(tester, RoleTransactionMenu.riwayatKey).color,
        AppColors.greenLight,
      );
      expect(pillOf(tester, RoleTransactionMenu.setoranKey).color,
          Colors.transparent);
    });

    testWidgets('hover and ripple are the rail\'s own, on the pill only',
        (tester) async {
      await taps(tester, role: 'pengelola', onAddTransaction: () {});
      final railInk = tester
          .widgetList<InkResponse>(find.descendant(
              of: find.byType(NavigationRail),
              matching: find.bySubtype<InkResponse>()))
          .firstWhere((ink) => ink.hoverColor != null);

      for (final key in [
        RoleTransactionMenu.headerKey,
        RoleTransactionMenu.riwayatKey,
        RoleTransactionMenu.setoranKey,
      ]) {
        final ink = tester.widget<InkResponse>(find
            .descendant(
                of: find.byKey(key), matching: find.bySubtype<InkResponse>())
            .first);
        expect(ink.hoverColor, railInk.hoverColor, reason: '$key hover');
        expect(ink.splashColor, railInk.splashColor, reason: '$key splash');
        expect(ink.customBorder, isA<StadiumBorder>());
        expect(ink.containedInkWell, isTrue);
        final box = tester.renderObject<RenderBox>(find
            .descendant(
                of: find.byKey(key), matching: find.bySubtype<InkResponse>())
            .first);
        final rect = ink.getRectCallback(box)!();
        expect(rect.size, const Size(56, 32), reason: '$key ripple area');
      }
    });

    testWidgets('a row without onTap is greyed like a disabled destination',
        (tester) async {
      // The menu draws no inert row any more (PIL-434), so this pins the
      // contract on RoleMenuRow itself - it is the same conditional that
      // reports `enabled` to a screen reader.
      await pumpRouted(
        tester,
        const Scaffold(
          body: RoleMenuRow(icon: Icons.payments_outlined, label: 'Contoh'),
        ),
        size: const Size(1440, 900),
      );
      final grey = Theme.of(tester.element(find.byType(RoleMenuRow)))
          .colorScheme
          .onSurface
          .withValues(alpha: 0.38);

      expect(tester.widget<RoleMenuRow>(find.byType(RoleMenuRow)).enabled,
          isFalse);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.payments_outlined)).color,
        grey,
      );
      expect(tester.widget<Text>(find.text('Contoh')).style?.color, grey);
      final ink = tester.widget<InkResponse>(find
          .descendant(
              of: find.byType(RoleMenuRow),
              matching: find.bySubtype<InkResponse>())
          .first);
      expect(ink.onTap, isNull);
    });

    testWidgets('the Transaksi label lines up with the destination labels',
        (tester) async {
      await taps(tester, role: 'pengelola', onAddTransaction: () {});

      expect(
        tester.getTopLeft(find.text('Transaksi')).dx,
        tester.getTopLeft(find.text('Dashboard')).dx,
      );
      expect(
        tester.getTopLeft(find.text('Setoran')).dx,
        greaterThan(tester.getTopLeft(find.text('Transaksi')).dx),
        reason: 'the children are indented under the group',
      );
    });

    testWidgets('the Transaksi header tells screen readers if it is open',
        (tester) async {
      final handle = tester.ensureSemantics();
      await taps(tester, role: 'pengelola', onAddTransaction: () {});

      Tristate expanded() => tester
          .getSemantics(find.byKey(RoleTransactionMenu.headerKey))
          .getSemanticsData()
          .flagsCollection
          .isExpanded;

      expect(expanded(), Tristate.isTrue);
      await tester.tap(find.text('Transaksi'));
      await tester.pumpAndSettle();
      expect(expanded(), Tristate.isFalse);
      handle.dispose();
    });

    testWidgets('rows other than the header carry no expanded state',
        (tester) async {
      final handle = tester.ensureSemantics();
      await taps(tester, role: 'pengelola', onAddTransaction: () {});

      final setoran = tester
          .getSemantics(find.byKey(RoleTransactionMenu.setoranKey))
          .getSemanticsData()
          .flagsCollection;

      expect(setoran.isExpanded, Tristate.none);
      handle.dispose();
    });

    testWidgets('the destinations follow Transaksi without a wide gap',
        (tester) async {
      await taps(tester, role: 'pengelola', onAddTransaction: () {});
      double centerY(Finder finder) => tester.getCenter(finder).dy;
      // A row is 48dp; only a few dp of separation on top of it, so the
      // Transaksi group sits next to the destinations like any other item.
      const oneRowAndASeparation = kMinInteractiveDimension + 8;

      expect(
        centerY(find.text('Dashboard')) - centerY(find.text('Setoran')),
        lessThanOrEqualTo(oneRowAndASeparation),
      );

      await tester.tap(find.text('Transaksi'));
      await tester.pumpAndSettle();
      expect(
        centerY(find.text('Dashboard')) - centerY(find.text('Transaksi')),
        lessThanOrEqualTo(oneRowAndASeparation),
      );
    });

    testWidgets('tapping Transaksi folds and unfolds its rows', (tester) async {
      await taps(tester, role: 'pengelola', onAddTransaction: () {});

      await tester.tap(find.text('Transaksi'));
      await tester.pumpAndSettle();
      expect(find.text('Setoran'), findsNothing);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);

      await tester.tap(find.text('Transaksi'));
      await tester.pumpAndSettle();
      expect(find.text('Setoran'), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
    });
  });
}
