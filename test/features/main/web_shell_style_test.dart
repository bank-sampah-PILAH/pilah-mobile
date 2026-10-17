import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_navigation_rail.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/web_content_surface.dart';

import '../../support/pump_app.dart';

/// On the web the rail and the page used to be the same near-white, so the
/// navigation melted into the content and white cards had nothing to stand on.
/// The rail is now a white panel with a border, the page sits on the grey page
/// colour, and the labels use the strong secondary text colour.
void main() {
  var profileTaps = 0;

  Future<void> mountRail(WidgetTester tester,
      {Size? window, String? profileName = 'Sari Dewi'}) async {
    profileTaps = 0;
    await pumpRouted(
      tester,
      Scaffold(
        body: Row(children: [
          RoleNavigationRail(
            role: 'pengelola',
            currentIndex: 0,
            bankSampahNama: 'Bank Sampah Melati',
            profileName: profileName,
            profileEmail: 'sari@example.test',
            onProfile: () => profileTaps++,
            onSelected: (_) {},
          ),
          const Expanded(child: SizedBox.shrink()),
        ]),
      ),
      size: window ?? const Size(1440, 900),
    );
  }

  group('RoleNavigationRail panel', () {
    testWidgets('is a white panel separated from the page by a border',
        (tester) async {
      await mountRail(tester);

      final panel =
          tester.widget<DecoratedBox>(find.byKey(RoleNavigationRail.panelKey));
      final decoration = panel.decoration as BoxDecoration;
      expect(decoration.color, Colors.white);
      expect((decoration.border! as Border).right.color, AppColors.grey200);
      expect((decoration.border! as Border).right.width, greaterThan(0));
    });

    testWidgets(
        'marks the selected item with a green tint and keeps the rest '
        'in the strong secondary text colour', (tester) async {
      await mountRail(tester);

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.indicatorColor, AppColors.greenLight);
      expect(rail.unselectedLabelTextStyle!.color, AppColors.inkSoft);
      expect(rail.selectedLabelTextStyle!.color, AppColors.greenDark);
      expect(rail.unselectedIconTheme!.color, AppColors.inkSoft);
    });

    testWidgets('shows the brand and a MENU label on the extended rail',
        (tester) async {
      await mountRail(tester);

      expect(find.text('PILAH'), findsOneWidget);
      expect(find.text('MENU'), findsOneWidget);
      expect(find.byKey(RoleNavigationRail.logoKey), findsOneWidget);
    });

    testWidgets('separates the brand from the bank sampah with a line',
        (tester) async {
      await mountRail(tester);

      final line = tester
          .widget<Divider>(find.byKey(RoleNavigationRail.headerDividerKey));
      expect(line.color, AppColors.border);
      final brand =
          tester.getBottomLeft(find.byKey(RoleNavigationRail.logoKey));
      final bank = tester.getTopLeft(find.text('Bank Sampah Melati'));
      final dividerY =
          tester.getCenter(find.byKey(RoleNavigationRail.headerDividerKey)).dy;
      expect(dividerY, greaterThan(brand.dy));
      expect(dividerY, lessThan(bank.dy));
    });

    testWidgets('keeps only the logo on the narrow rail', (tester) async {
      await mountRail(tester, window: const Size(700, 900));

      expect(find.byKey(RoleNavigationRail.logoKey), findsOneWidget);
      expect(find.text('PILAH'), findsNothing);
      expect(find.text('MENU'), findsNothing);
    });
  });

  group('RoleNavigationRail labels', () {
    testWidgets('are small and light enough to match the design',
        (tester) async {
      await mountRail(tester);

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.unselectedLabelTextStyle!.fontSize, 12);
      expect(rail.unselectedLabelTextStyle!.fontWeight, FontWeight.w500);
      expect(rail.selectedLabelTextStyle!.fontSize, 12);
      expect(rail.selectedLabelTextStyle!.fontWeight, FontWeight.w600);
    });
  });

  group('RoleNavigationRail profile', () {
    testWidgets('sits at the bottom with the name and email', (tester) async {
      await mountRail(tester);

      expect(find.text('Sari Dewi'), findsOneWidget);
      expect(find.text('sari@example.test'), findsOneWidget);
      expect(find.text('SD'), findsOneWidget);
      expect(tester.getBottomLeft(find.byKey(RoleNavigationRail.profileKey)).dy,
          greaterThan(800));
    });

    testWidgets('is outlined so it stands out from the menu', (tester) async {
      await mountRail(tester);

      final card = tester
          .widget<DecoratedBox>(find.byKey(RoleNavigationRail.profileCardKey));
      final decoration = card.decoration as BoxDecoration;
      expect((decoration.border! as Border).top.color, AppColors.border);
      expect(decoration.borderRadius, BorderRadius.circular(12));
    });

    testWidgets('opens the profile when tapped', (tester) async {
      await mountRail(tester);

      await tester.tap(find.byKey(RoleNavigationRail.profileKey));
      expect(profileTaps, 1);
    });

    testWidgets('shrinks to the avatar on the narrow rail', (tester) async {
      await mountRail(tester, window: const Size(700, 900));

      expect(find.text('SD'), findsOneWidget);
      expect(find.text('Sari Dewi'), findsNothing);
      expect(find.text('sari@example.test'), findsNothing);
      await tester.tap(find.byKey(RoleNavigationRail.profileKey));
      expect(profileTaps, 1);
    });

    testWidgets('is left out when the session has no name', (tester) async {
      await mountRail(tester, profileName: null);

      expect(find.byKey(RoleNavigationRail.profileKey), findsNothing);
    });
  });

  group('WebContentSurface', () {
    testWidgets('puts pages on the grey page colour', (tester) async {
      late Color background;
      await tester.pumpWidget(MaterialApp(
        home: WebContentSurface(
          child: Builder(builder: (context) {
            background = Theme.of(context).scaffoldBackgroundColor;
            return const Scaffold(body: Text('page'));
          }),
        ),
      ));

      expect(background, AppColors.surface);
    });

    testWidgets('lets a page that paints its own background follow it',
        (tester) async {
      late Color inside;
      late Color outside;
      await tester.pumpWidget(MaterialApp(
        home: Column(children: [
          Builder(builder: (context) {
            outside = WebContentSurface.pageColor(context, phone: Colors.white);
            return const SizedBox();
          }),
          WebContentSurface(
            child: Builder(builder: (context) {
              inside =
                  WebContentSurface.pageColor(context, phone: Colors.white);
              return const SizedBox();
            }),
          ),
        ]),
      ));

      expect(inside, AppColors.surface);
      expect(outside, Colors.white,
          reason: 'the phone layout keeps the colour it has today');
    });
  });
}
