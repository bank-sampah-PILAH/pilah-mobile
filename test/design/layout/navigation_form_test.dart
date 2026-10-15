import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/layout/navigation_form.dart';

/// Lead dev's rule: in the app the navigation sits at the bottom, in a browser
/// it sits on the left. Platform decides the *family*, width only decides how
/// much of the left-hand navigation is shown.
///
/// Deciding this on width alone was wrong in both directions: a native phone
/// held sideways is wider than 840 and would lose its bottom bar, and a browser
/// window narrowed below 600 would grow one.
void main() {
  group('NavigationForm.resolve on native', () {
    test('a phone gets the bottom bar', () {
      expect(
        NavigationForm.resolve(isWeb: false, width: 390),
        NavigationForm.bottomBar,
      );
    });

    test('a tablet still gets the bottom bar', () {
      expect(
        NavigationForm.resolve(isWeb: false, width: 820),
        NavigationForm.bottomBar,
        reason: 'width must not promote the app to a rail',
      );
    });

    test('a phone held sideways still gets the bottom bar', () {
      expect(
        NavigationForm.resolve(isWeb: false, width: 844),
        NavigationForm.bottomBar,
        reason: 'landscape is not a desktop; this was the bug',
      );
    });
  });

  group('NavigationForm.resolve on web', () {
    test('a desktop window gets the labelled rail', () {
      expect(
        NavigationForm.resolve(isWeb: true, width: 1440),
        NavigationForm.railExtended,
      );
    });

    test('a tablet window gets the collapsed rail', () {
      expect(
        NavigationForm.resolve(isWeb: true, width: 720),
        NavigationForm.railCollapsed,
      );
    });

    test('a phone browser gets a drawer behind a menu button', () {
      expect(
        NavigationForm.resolve(isWeb: true, width: 390),
        NavigationForm.drawer,
        reason: 'a 256px rail cannot share a 390px window with content',
      );
    });

    test('the drawer-to-rail boundary belongs to the rail', () {
      expect(NavigationForm.resolve(isWeb: true, width: 599),
          NavigationForm.drawer);
      expect(NavigationForm.resolve(isWeb: true, width: 600),
          NavigationForm.railCollapsed);
    });

    test('the collapsed-to-labelled boundary belongs to the labelled rail', () {
      expect(NavigationForm.resolve(isWeb: true, width: 839),
          NavigationForm.railCollapsed);
      expect(NavigationForm.resolve(isWeb: true, width: 840),
          NavigationForm.railExtended);
    });

    test('a width that is not known yet gets the drawer, not an empty page',
        () {
      expect(
        NavigationForm.resolve(isWeb: true, width: 0),
        NavigationForm.drawer,
        reason: 'the first frame can run before the window size is known',
      );
    });
  });

  group('NavigationForm shape', () {
    test('only the drawer form hides the destinations behind a button', () {
      expect(NavigationForm.drawer.isOverlay, isTrue);
      for (final form in [
        NavigationForm.bottomBar,
        NavigationForm.railCollapsed,
        NavigationForm.railExtended,
      ]) {
        expect(form.isOverlay, isFalse, reason: '$form is always visible');
      }
    });

    test('both rail forms are rails, and nothing else is', () {
      expect(NavigationForm.railCollapsed.isRail, isTrue);
      expect(NavigationForm.railExtended.isRail, isTrue);
      expect(NavigationForm.bottomBar.isRail, isFalse);
      expect(NavigationForm.drawer.isRail, isFalse);
    });
  });
}
