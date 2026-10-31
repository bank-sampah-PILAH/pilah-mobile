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

    /// Width is not the whole rule, and the comment above was wrong to say it
    /// was. PIL-432 is a **web** ticket: in the native app a long form keeps
    /// its own full-screen route at every width. A phone is always compact, so
    /// the width rule agreed with the platform rule there by accident — but a
    /// native tablet is 768 wide and is not compact, and the width-only
    /// resolver handed it a panel it was never meant to get.
    ///
    /// Raised on review of PR #186.
    group('the platform', () {
      test('a native tablet keeps the full-screen page', () {
        expect(
          SideSheetPresentation.resolve(width: 768, isWebOverride: false),
          SideSheetPresentation.fullScreen,
          reason: 'a tablet is not compact, so width alone said side sheet; '
              'the native app has no browser shell to leave behind',
        );
      });

      test('a native window as wide as a desktop keeps it too', () {
        expect(
          SideSheetPresentation.resolve(width: 1440, isWebOverride: false),
          SideSheetPresentation.fullScreen,
        );
      });

      test('the same tablet width on the web gets a side sheet', () {
        expect(
          SideSheetPresentation.resolve(width: 768, isWebOverride: true),
          SideSheetPresentation.sideSheet,
        );
      });

      test('a narrow web window still keeps the full-screen page', () {
        expect(
          SideSheetPresentation.resolve(width: 390, isWebOverride: true),
          SideSheetPresentation.fullScreen,
          reason: 'the width rule still applies on the web; the platform gate '
              'only removes a case, it does not replace the rule',
        );
      });
    });
  });

  /// The whole point of the panel is that the page stays behind it, so how wide
  /// the panel is cannot be one fixed number: 560 of a 600 px window leaves a
  /// 40 px sliver, which reads as a broken full-screen page rather than a
  /// panel. The rule is therefore a cap *and* a floor on what stays uncovered,
  /// and the second half is what the fixed number would have missed.
  group('SideSheetPresentation.widthFor', () {
    test('a desktop window gets the preferred width', () {
      expect(
        SideSheetPresentation.widthFor(1440),
        SideSheetPresentation.maxWidth,
      );
    });

    test('the narrowest side-sheet window gets a narrower panel', () {
      expect(
        SideSheetPresentation.widthFor(LayoutBreakpoint.mediumMinWidth),
        LayoutBreakpoint.mediumMinWidth - SideSheetPresentation.minPageVisible,
        reason: 'a 560 panel would leave a 40 px sliver of the page',
      );
    });

    test('the panel stops growing once the page has room to spare', () {
      const firstFullWidthWindow =
          SideSheetPresentation.maxWidth + SideSheetPresentation.minPageVisible;
      expect(
        SideSheetPresentation.widthFor(firstFullWidthWindow),
        SideSheetPresentation.maxWidth,
      );
      expect(
        SideSheetPresentation.widthFor(firstFullWidthWindow - 1),
        SideSheetPresentation.maxWidth - 1,
        reason: 'just below it the panel gives the pixel back to the page',
      );
    });

    test('every window that gets a side sheet gets a usable one', () {
      // Swept rather than sampled: the two bounds are the whole contract, and
      // a cap written the wrong way round still satisfies any single example.
      for (var window = LayoutBreakpoint.mediumMinWidth;
          window <= 2560;
          window += 7) {
        final panel = SideSheetPresentation.widthFor(window);
        expect(
          panel,
          greaterThan(0),
          reason: 'a $window px window got no panel at all',
        );
        expect(
          window - panel,
          greaterThanOrEqualTo(SideSheetPresentation.minPageVisible),
          reason: 'the panel covered too much of a $window px window',
        );
      }
    });
  });
}
