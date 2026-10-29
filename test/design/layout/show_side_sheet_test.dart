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
  Future<void> open(
    WidgetTester tester,
    Size window, {
    bool Function()? hasUnsavedInput,
  }) async {
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
                  hasUnsavedInput: hasUnsavedInput,
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

  /// The full-screen page never needed this guard: you leave it by pressing
  /// back, which is deliberate. A panel adds a way out that is not — the scrim
  /// is most of a wide window, and a mis-aimed click on it would throw away a
  /// half-typed setoran with no way to get it back.
  ///
  /// The guard belongs to the container rather than to the form, so every
  /// panel asks the same question in the same words. It reads the form's
  /// dirtiness at the moment of the attempt, not when the panel was built,
  /// because that is when the answer actually matters.
  group('a panel holding unsaved input', () {
    const question = 'Buang isi formulir?';

    testWidgets('is not thrown away by a click on the scrim', (tester) async {
      await open(tester, const Size(1440, 900), hasUnsavedInput: () => true);

      await tester.tapAt(const Offset(100, 450));
      await tester.pumpAndSettle();

      expect(find.text(question), findsOneWidget);
      expect(find.byKey(contentKey), findsOneWidget,
          reason: 'the input is still there while the question is open');
    });

    testWidgets('stays open when the question is declined', (tester) async {
      await open(tester, const Size(1440, 900), hasUnsavedInput: () => true);
      await tester.tapAt(const Offset(100, 450));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lanjut mengisi'));
      await tester.pumpAndSettle();

      expect(find.text(question), findsNothing);
      expect(find.byKey(contentKey), findsOneWidget);
    });

    testWidgets('closes once discarding is confirmed', (tester) async {
      await open(tester, const Size(1440, 900), hasUnsavedInput: () => true);
      await tester.tapAt(const Offset(100, 450));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buang'));
      await tester.pumpAndSettle();

      expect(find.byKey(contentKey), findsNothing);
      expect(result, isNull, reason: 'nothing was saved');
    });

    testWidgets('is asked about on escape as well as on the scrim',
        (tester) async {
      await open(tester, const Size(1440, 900), hasUnsavedInput: () => true);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text(question), findsOneWidget);
    });

    testWidgets('is read again on each attempt, not cached', (tester) async {
      var dirty = false;
      await open(tester, const Size(1440, 900), hasUnsavedInput: () => dirty);

      dirty = true;
      await tester.tapAt(const Offset(100, 450));
      await tester.pumpAndSettle();

      expect(find.text(question), findsOneWidget,
          reason: 'the form became dirty after the panel was built, which is '
              'the only order that ever happens in practice');
    });

    testWidgets('does not second-guess the form closing itself',
        (tester) async {
      await open(tester, const Size(1440, 900), hasUnsavedInput: () => true);

      await tester.tap(find.text('selesai'));
      await tester.pumpAndSettle();

      expect(find.text(question), findsNothing,
          reason: 'a successful submit leaves input unsaved by definition; '
              'asking there would block the save it just made');
      expect(find.byKey(contentKey), findsNothing);
      expect(result, 'tersimpan');
    });
  });

  testWidgets('a panel with nothing in it closes without asking',
      (tester) async {
    await open(tester, const Size(1440, 900), hasUnsavedInput: () => false);

    await tester.tapAt(const Offset(100, 450));
    await tester.pumpAndSettle();

    expect(find.byKey(contentKey), findsNothing);
    expect(find.text('Buang isi formulir?'), findsNothing);
  });
}
