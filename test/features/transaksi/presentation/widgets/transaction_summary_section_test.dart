import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/transaction_summary_section.dart';

import '../../../../support/pump_app.dart';

/// The grand total row puts a label and an amount in a `Row` with neither one
/// flexible. The existing page tests run on an 800px-wide surface, so nothing
/// has ever exercised it at a real phone width — and at 390, the width of an
/// iPhone 12 through 16, it overflows.
///
/// A money figure is the one thing on this screen that must not be clipped or
/// ellipsised, so the fix has to shrink it rather than truncate it.
void main() {
  Future<void> mount(WidgetTester tester, int grandTotal, Size window) async {
    await pumpRouted(
      tester,
      Scaffold(body: TransactionSummarySection(grandTotal: grandTotal)),
      size: window,
    );
  }

  group('TransactionSummarySection', () {
    testWidgets('fits a 390px phone', (tester) async {
      await mount(tester, 1250000, const Size(390, 900));
      expect(tester.takeException(), isNull,
          reason: '390 is the commonest phone width; the row must fit it');
    });

    testWidgets('fits a very narrow window with a large amount',
        (tester) async {
      await mount(tester, 999999999, const Size(320, 900));
      expect(tester.takeException(), isNull,
          reason: 'a nine-figure total on a 320px screen is the worst case');
    });

    testWidgets('shows the whole amount rather than clipping it',
        (tester) async {
      await mount(tester, 1250000, const Size(390, 900));
      expect(find.text('Rp 1.250.000'), findsOneWidget,
          reason: 'money may be scaled down, never truncated');
    });

    testWidgets('still fits comfortably on a wide window', (tester) async {
      await mount(tester, 1250000, const Size(1440, 900));
      expect(tester.takeException(), isNull);
      expect(find.text('Rp 1.250.000'), findsOneWidget);
    });

    testWidgets('a zero total is shown, not hidden', (tester) async {
      await mount(tester, 0, const Size(390, 900));
      expect(tester.takeException(), isNull);
      expect(find.text('Rp 0'), findsOneWidget);
    });
  });
}
