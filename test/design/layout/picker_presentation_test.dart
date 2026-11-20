import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/design/layout/picker_presentation.dart';

/// Which container a modal picker gets is a rule about the window, and like
/// `NavigationForm.resolve` it is worth deciding in one pure function rather
/// than with a `MediaQuery` check at each call site. There are four pickers in
/// this feature alone.
///
/// Unlike navigation, the discriminator here is *width*, not platform. The
/// lead dev's rule — bottom bar in the app, left-hand navigation in a browser —
/// is about the persistent navigation chrome. A picker is transient, and
/// Material's own guidance ties it to the window size class: sheets are the
/// compact-window pattern, dialogs are for medium and up. The two rules agree
/// everywhere it matters anyway, because a native phone is compact.
void main() {
  group('PickerPresentation.resolve', () {
    test('a phone gets a bottom sheet', () {
      expect(PickerPresentation.resolve(width: 390),
          PickerPresentation.bottomSheet);
    });

    test('a desktop browser window gets a dialog', () {
      expect(
          PickerPresentation.resolve(width: 1280), PickerPresentation.dialog);
    });

    test('a tablet-width window gets a dialog', () {
      expect(PickerPresentation.resolve(width: 768), PickerPresentation.dialog);
    });

    group('the boundary', () {
      test('one pixel below medium is still a sheet', () {
        expect(
          PickerPresentation.resolve(
              width: LayoutBreakpoint.mediumMinWidth - 1),
          PickerPresentation.bottomSheet,
        );
      });

      test('exactly medium is already a dialog', () {
        expect(
          PickerPresentation.resolve(width: LayoutBreakpoint.mediumMinWidth),
          PickerPresentation.dialog,
          reason: 'the boundary belongs to the wider block, as in '
              'LayoutBreakpoint.fromWidth',
        );
      });

      test('a zero width is a sheet rather than a crash', () {
        expect(PickerPresentation.resolve(width: 0),
            PickerPresentation.bottomSheet,
            reason: 'the first frame can run before the size is known');
      });
    });
  });
}
