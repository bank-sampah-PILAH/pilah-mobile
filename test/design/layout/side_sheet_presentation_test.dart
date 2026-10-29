import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/design/layout/side_sheet_presentation.dart';

/// A form that fills the window destroys the context it was opened from: the
/// Pengurus loses the navigation rail and the list they were working through.
/// On a phone that is unavoidable and right. On a wide window it is a choice,
/// and the better one is a panel at the edge with the page still behind it.
///
/// Which of the two a window gets is a rule about width, so it is decided in
/// one pure function here rather than with a `MediaQuery` check at each call
/// site — the same split `PickerPresentation.resolve` already makes for modal
/// pickers, and for the same reason: a native phone is always compact, so the
/// width rule and the platform rule agree everywhere it matters.
void main() {
  group('SideSheetPresentation.resolve', () {
    test('a phone keeps the full-screen page', () {
      expect(
        SideSheetPresentation.resolve(width: 390),
        SideSheetPresentation.fullScreen,
      );
    });

    test('a tablet-width window gets a side sheet', () {
      expect(
        SideSheetPresentation.resolve(width: 768),
        SideSheetPresentation.sideSheet,
      );
    });

    test('a desktop browser window gets a side sheet', () {
      expect(
        SideSheetPresentation.resolve(width: 1440),
        SideSheetPresentation.sideSheet,
      );
    });

    group('the boundary', () {
      test('one pixel below medium is still a full-screen page', () {
        expect(
          SideSheetPresentation.resolve(
            width: LayoutBreakpoint.mediumMinWidth - 1,
          ),
          SideSheetPresentation.fullScreen,
        );
      });

      test('exactly medium is already a side sheet', () {
        expect(
          SideSheetPresentation.resolve(
            width: LayoutBreakpoint.mediumMinWidth,
          ),
          SideSheetPresentation.sideSheet,
          reason: 'the boundary belongs to the wider block, as in '
              'LayoutBreakpoint.fromWidth',
        );
      });

      test('a zero width is a full-screen page rather than a crash', () {
        expect(
          SideSheetPresentation.resolve(width: 0),
          SideSheetPresentation.fullScreen,
          reason: 'the first frame can run before the size is known',
        );
      });

      test('a negative width is a full-screen page too', () {
        expect(
          SideSheetPresentation.resolve(width: -1),
          SideSheetPresentation.fullScreen,
        );
      });
    });
  });
}
