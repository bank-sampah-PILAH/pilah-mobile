import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/layout/side_sheet_presentation.dart';

/// `SideSheetPage` is the one way a long form opens as a panel at the edge of a
/// wide window. All of the container — where it sits, how wide it is at this
/// window width, the scrim, the slide, and the question it asks before unsaved
/// input is thrown away — lives in the page rather than at the call site, for
/// the same reason `showAdaptivePicker` does it: four call sites answering the
/// question separately is four chances to answer it differently.
///
/// It is a **route**, declared like any other, not a dialog opened on the
/// navigator by hand. That distinction is the whole point and it was paid for:
/// as a `showGeneralDialog` the panel added no browser history entry, so the
/// browser back button popped the page *underneath* it and a half-typed
/// setoran was destroyed with no question asked. Measured in a real browser on
/// 30 October 2026: `history.length` unchanged, `#/dashboard` → `#/login`.
void main() {
  const contentKey = Key('side-sheet-content');

  /// What the panel answered, so a caller's `await` is observable.
  String? result;

  /// The guard the panel was opened with, so the browser-back path — which
  /// goes through `GoRoute.onExit` and never through `PopScope` — can be
  /// exercised the way go_router exercises it.
  late SideSheetGuard guard;

  setUp(() => result = null);

  /// Opens the panel as a route on top of a page that stays identifiable, so
  /// whether the page beneath survives is observable.
  Future<void> open(
    WidgetTester tester,
    Size window, {
    bool Function()? hasUnsavedInput,
    bool guarded = true,
  }) async {
    guard = SideSheetGuard(hasUnsavedInput: hasUnsavedInput ?? () => false);
    tester.view.physicalSize = window;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (pageContext) => TextButton(
            onPressed: () async {
              final page = SideSheetPage<String>(
                guard: guarded ? guard : null,
                child: Builder(
                  builder: (sheetContext) => SizedBox.expand(
                    key: contentKey,
                    child: Column(
                      children: [
                        const Text('isi panel'),
                        TextButton(
                          onPressed: () {
                            guard.allowNextExit();
                            Navigator.of(sheetContext).pop('tersimpan');
                          },
                          child: const Text('selesai'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
              result = await Navigator.of(pageContext)
                  .push(page.createRoute(pageContext));
            },
            child: const Text('buka'),
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

  testWidgets('the page underneath stays mounted and visible', (tester) async {
    await open(tester, const Size(1440, 900));

    expect(find.byKey(contentKey), findsOneWidget);
    expect(
      find.text('buka'),
      findsOneWidget,
      reason: 'an opaque route would take the page beneath off the tree, and '
          'a page left visible behind the panel is the entire point',
    );
  });

  /// Four ways out, all of them in the acceptance criteria. They are pinned
  /// here because they are the reason the panel is a route at all: an
  /// `OverlayEntry` would have to re-implement each one.
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

    /// The platform back gesture, which goes through `Navigator.maybePop` and
    /// so through `PopScope`. The browser's back button does **not** — see the
    /// `onExit` group below. Keeping both is the point: they are different
    /// paths and only one of them was ever covered.
    testWidgets('a platform back closes the panel, not the page beneath it',
        (tester) async {
      await open(tester, const Size(1440, 900));

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byKey(contentKey), findsNothing);
      expect(find.text('buka'), findsOneWidget,
          reason: 'this is the browser back button: it must take the panel '
              'and leave the page the Pengurus was working on');
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
  /// back, which is deliberate. A panel adds ways out that are not — the scrim
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

    testWidgets('is asked about on a platform back as well', (tester) async {
      await open(tester, const Size(1440, 900), hasUnsavedInput: () => true);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text(question), findsOneWidget);
      expect(find.byKey(contentKey), findsOneWidget,
          reason: 'back must not destroy the form before the question is '
              'answered');
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

    /// The bypass has to hold on **both** exits.
    ///
    /// A form that saved and then leaves through `maybePop` — a platform back,
    /// or its own `maybePop` rather than a bare `pop` — is exactly what
    /// [SideSheetGuard.allowNextExit] exists for, and `handlePopAttempt` read
    /// only `hasUnsavedInput`, so it asked anyway and blocked the save.
    /// Reported on review of PR #186.
    testWidgets('is not questioned once the form allowed the next exit',
        (tester) async {
      await open(tester, const Size(1440, 900), hasUnsavedInput: () => true);

      guard.allowNextExit();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text(question), findsNothing,
          reason: 'the form has already decided; asking here blocks the save '
              'it just made, which is the whole reason for the bypass');
      expect(find.byKey(contentKey), findsNothing);
    });

    /// And the key must be handed on, not spent: go_router runs `onExit` for
    /// the pop that just happened, so a bypass consumed by `handlePopAttempt`
    /// would leave `onExit` to ask about the very pop the form allowed.
    testWidgets('hands the one-shot key on to the onExit of the same pop',
        (tester) async {
      await open(tester, const Size(1440, 900), hasUnsavedInput: () => true);

      guard.allowNextExit();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(question), findsNothing);

      // The page beneath the panel is still mounted, so it can stand in for
      // the context go_router would call `onExit` with.
      final context = tester.element(find.text('buka'));
      expect(await guard.confirmExit(context), isTrue);
      await tester.pumpAndSettle();

      expect(find.text(question), findsNothing,
          reason: 'onExit must not question the pop the form allowed');
    });
  });

  /// The browser back button, which is the path the first fix missed.
  ///
  /// It never pops anything: the history entry changes, go_router rebuilds its
  /// page list and the route is removed declaratively. `PopScope` is a
  /// `PopEntry` and only `Navigator.maybePop` reads one, so that exit skipped
  /// the guard entirely and destroyed a setoran in a real browser. go_router
  /// offers `GoRoute.onExit` for exactly this, and [SideSheetGuard.confirmExit]
  /// is what goes there.
  group('leaving through the browser history', () {
    const question = 'Buang isi formulir?';

    testWidgets('a dirty panel is not left without asking', (tester) async {
      await open(tester, const Size(1440, 900), hasUnsavedInput: () => true);

      final exit = guard.confirmExit(tester.element(find.byKey(contentKey)));
      await tester.pumpAndSettle();

      expect(find.text(question), findsOneWidget);
      await tester.tap(find.text('Lanjut mengisi'));
      await tester.pumpAndSettle();

      expect(await exit, isFalse,
          reason: 'false aborts the history navigation, so the panel and the '
              'setoran in it both stay');
    });

    testWidgets('a dirty panel is left once discarding is confirmed',
        (tester) async {
      await open(tester, const Size(1440, 900), hasUnsavedInput: () => true);

      final exit = guard.confirmExit(tester.element(find.byKey(contentKey)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buang'));
      await tester.pumpAndSettle();

      expect(await exit, isTrue);
    });

    testWidgets('a clean panel is left without a question', (tester) async {
      await open(tester, const Size(1440, 900), hasUnsavedInput: () => false);

      final left = await guard.confirmExit(
        tester.element(find.byKey(contentKey)),
      );
      await tester.pumpAndSettle();

      expect(left, isTrue);
      expect(find.text(question), findsNothing);
    });

    /// With `onExit` mounted, go_router runs it for *every* pop, including the
    /// one the scrim just asked about. Without the one-shot key that single
    /// click would be questioned twice.
    testWidgets('a close that was already answered is not asked again',
        (tester) async {
      await open(tester, const Size(1440, 900), hasUnsavedInput: () => true);
      final context = tester.element(find.byKey(contentKey));

      guard.allowNextExit();
      expect(await guard.confirmExit(context), isTrue);
      await tester.pumpAndSettle();
      expect(find.text(question), findsNothing);

      // One shot only: the next attempt is a fresh one and asks again.
      final exit = guard.confirmExit(context);
      await tester.pumpAndSettle();
      expect(find.text(question), findsOneWidget);
      await tester.tap(find.text('Lanjut mengisi'));
      await tester.pumpAndSettle();
      expect(await exit, isFalse);
    });
  });

  /// `guard` is optional, and a panel with nothing to lose must not be harder
  /// to close than one that guards its input.
  ///
  /// The container blocks the pop so that a guard can answer it. With no guard
  /// there is nobody to answer, so the pop has to go through on its own — and
  /// it did not: `canPop` was false unconditionally and the callback was
  /// null-aware, so the scrim, Esc and the platform back each did nothing at
  /// all and the panel could not be dismissed by any means. Found on review of
  /// PR #186, by two reviewers independently.
  group('a panel opened without a guard', () {
    testWidgets('closes on a click beside it', (tester) async {
      await open(tester, const Size(1440, 900), guarded: false);
      expect(find.byKey(contentKey), findsOneWidget);

      await tester.tapAt(const Offset(100, 450));
      await tester.pumpAndSettle();

      expect(find.byKey(contentKey), findsNothing);
    });

    testWidgets('closes on escape', (tester) async {
      await open(tester, const Size(1440, 900), guarded: false);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byKey(contentKey), findsNothing);
    });

    testWidgets('closes on a platform back, leaving the page beneath it',
        (tester) async {
      await open(tester, const Size(1440, 900), guarded: false);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byKey(contentKey), findsNothing);
      expect(find.text('buka'), findsOneWidget);
    });

    testWidgets('still answers the value the form popped with', (tester) async {
      await open(tester, const Size(1440, 900), guarded: false);

      await tester.tap(find.text('selesai'));
      await tester.pumpAndSettle();

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
  });
}
