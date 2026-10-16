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
  Future<void> mountRail(WidgetTester tester, {Size? window}) async {
    await pumpRouted(
      tester,
      Scaffold(
        body: Row(children: [
          RoleNavigationRail(
            role: 'pengelola',
            currentIndex: 0,
            bankSampahNama: 'Bank Sampah Melati',
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
      expect((decoration.border! as Border).right.color, AppColors.border);
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

    testWidgets('keeps only the logo on the narrow rail', (tester) async {
      await mountRail(tester, window: const Size(700, 900));

      expect(find.byKey(RoleNavigationRail.logoKey), findsOneWidget);
      expect(find.text('PILAH'), findsNothing);
      expect(find.text('MENU'), findsNothing);
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
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNull,
          reason: 'the page keeps the theme default so the override applies');
    });
  });
}
