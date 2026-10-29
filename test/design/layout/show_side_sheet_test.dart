import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/layout/side_sheet_presentation.dart';

/// `showSideSheet` is the one way a long form opens as a panel at the edge of a
/// wide window. All of the container — where it sits, how wide it is, the
/// scrim, the slide — lives in the helper rather than at the call site, for the
/// same reason `showAdaptivePicker` does it: four call sites answering the
/// question separately is four chances to answer it differently.
///
/// It opens on the **root** navigator. The setoran form is reachable from the
/// dashboard, from the web rail and from its own route, and the shell those
/// sit in has nested navigators of its own; a panel pushed onto a nested one
/// would be clipped to that branch and would vanish when the branch changed.
void main() {
  const contentKey = Key('side-sheet-content');
  final nestedNavigatorKey = GlobalKey<NavigatorState>();

  /// Opens the sheet from a context inside a *nested* navigator, so where the
  /// route actually lands is observable.
  Future<void> open(WidgetTester tester, Size window) async {
    tester.view.physicalSize = window;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Navigator(
          key: nestedNavigatorKey,
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            builder: (nestedContext) => TextButton(
              onPressed: () => showSideSheet<void>(
                context: nestedContext,
                builder: (_) => const SizedBox.expand(
                  key: contentKey,
                  child: Text('isi panel'),
                ),
              ),
              child: const Text('buka'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
  }

  testWidgets('the panel sits flush against the right edge of the window',
      (tester) async {
    await open(tester, const Size(1440, 900));

    final panel = tester.getRect(find.byKey(contentKey));
    expect(panel.right, 1440, reason: 'it is a panel at the edge, not a card');
    expect(panel.top, 0);
    expect(panel.bottom, 900, reason: 'it spans the full height of the window');
  });

  testWidgets('the panel is as wide as the width rule says', (tester) async {
    await open(tester, const Size(1440, 900));

    expect(
      tester.getRect(find.byKey(contentKey)).width,
      SideSheetPresentation.widthFor(1440),
    );
  });

  testWidgets('a narrower window gets a narrower panel, not a clipped one',
      (tester) async {
    await open(tester, const Size(600, 800));

    final panel = tester.getRect(find.byKey(contentKey));
    expect(panel.width, SideSheetPresentation.widthFor(600));
    expect(panel.right, 600);
  });

  testWidgets('the panel opens on the root navigator, not the nested one',
      (tester) async {
    await open(tester, const Size(1440, 900));

    expect(find.byKey(contentKey), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(nestedNavigatorKey),
        matching: find.byKey(contentKey),
      ),
      findsNothing,
      reason: 'a panel inside the nested navigator would go with its branch',
    );
  });

  testWidgets('shrinking the window to a phone keeps the panel inside it',
      (tester) async {
    await open(tester, const Size(1440, 900));

    // A browser window can be dragged narrow while the form is open. The panel
    // has to follow the window down instead of overflowing it or collapsing to
    // a negative width.
    tester.view.physicalSize = const Size(380, 800);
    await tester.pumpAndSettle();

    final panel = tester.getRect(find.byKey(contentKey));
    expect(panel.width, greaterThan(0));
    expect(panel.width, lessThanOrEqualTo(380));
    expect(panel.right, 380);
  });
}
