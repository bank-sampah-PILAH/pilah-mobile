import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// What the panel answered, so a caller's `await` is observable.
  String? result;
  setUp(() => result = null);

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
              onPressed: () async {
                result = await showSideSheet<String>(
                  context: nestedContext,
                  builder: (sheetContext) => SizedBox.expand(
                    key: contentKey,
                    child: Column(
                      children: [
                        const Text('isi panel'),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(sheetContext).pop('tersimpan'),
                          child: const Text('selesai'),
                        ),
                      ],
                    ),
                  ),
                );
              },
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

  /// Three ways out, all of them in the acceptance criteria. They are pinned
  /// here because they are the reason the panel is a route at all: an
  /// `OverlayEntry` would have to re-implement each one, and the browser back
  /// button could not be made to work at all.
  group('closing it', () {
    testWidgets('tapping the page beside the panel closes it', (tester) async {
      await open(tester, const Size(1440, 900));
      expect(find.byKey(contentKey), findsOneWidget);

      await tester.tapAt(const Offset(100, 450));
      await tester.pumpAndSettle();

      expect(find.byKey(contentKey), findsNothing);
    });

    testWidgets('pressing escape closes it', (tester) async {
      await open(tester, const Size(1440, 900));

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byKey(contentKey), findsNothing,
          reason: 'a keyboard user on the web expects escape to work');
    });

    testWidgets('popping the panel closes it and answers its value',
        (tester) async {
      await open(tester, const Size(1440, 900));

      await tester.tap(find.text('selesai'));
      await tester.pumpAndSettle();

      expect(find.byKey(contentKey), findsNothing);
      expect(result, 'tersimpan',
          reason: 'the form reports what it did through the sheet');
    });
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
