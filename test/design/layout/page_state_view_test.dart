import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/design/layout/page_state_view.dart';

import '../../support/pump_app.dart';

/// PRD 6.2.5 requires every data-backed screen to handle loading, empty and
/// failed states, not just success — and 6.2.6 requires an error message to
/// state both the problem and what the user can do about it.
///
/// EmptyView and SkeletonListItem already exist for the first two. What is
/// missing is the failed state with a way back, and a single place that picks
/// between all four so each web screen does not re-invent it.
void main() {
  const ready = Key('ready');

  Future<int> mount(
    WidgetTester tester, {
    required PageState state,
    String? errorMessage,
    bool retryable = true,
  }) async {
    var retries = 0;
    await pumpRouted(
      tester,
      Scaffold(
        body: PageStateView(
          state: state,
          emptyTitle: 'Belum ada nasabah',
          errorMessage: errorMessage,
          onRetry: retryable ? () => retries++ : null,
          child: const SizedBox.expand(key: ready),
        ),
      ),
      size: const Size(1440, 900),
    );
    return retries;
  }

  group('PageStateView', () {
    testWidgets('ready shows the content and nothing else', (tester) async {
      await mount(tester, state: PageState.ready);
      expect(find.byKey(ready), findsOneWidget);
      expect(find.byType(EmptyView), findsNothing);
    });

    testWidgets('loading hides the content behind a skeleton',
        (tester) async {
      await mount(tester, state: PageState.loading);
      expect(find.byKey(ready), findsNothing,
          reason: 'showing stale content while loading misleads the user');
    });

    testWidgets('empty explains the emptiness instead of showing a blank page',
        (tester) async {
      await mount(tester, state: PageState.empty);
      expect(find.byType(EmptyView), findsOneWidget);
      expect(find.text('Belum ada nasabah'), findsOneWidget);
      expect(find.byKey(ready), findsNothing);
    });

    testWidgets('error states the problem and offers a way back',
        (tester) async {
      await mount(tester,
          state: PageState.error, errorMessage: 'Koneksi terputus.');
      expect(find.text('Koneksi terputus.'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
    });

    testWidgets('retry calls back exactly once per press', (tester) async {
      var retries = 0;
      await pumpRouted(
        tester,
        Scaffold(
          body: PageStateView(
            state: PageState.error,
            onRetry: () => retries++,
            child: const SizedBox.shrink(),
          ),
        ),
        size: const Size(1440, 900),
      );
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(retries, 1);
    });

    testWidgets('an error with no message still says something useful',
        (tester) async {
      await mount(tester, state: PageState.error);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) =>
            w is Text && (w.data ?? '').isNotEmpty && w.data != 'Coba lagi'),
        findsWidgets,
        reason: 'a bare retry button does not tell the user what went wrong',
      );
    });

    testWidgets('an unretryable error omits the button rather than faking it',
        (tester) async {
      await mount(tester, state: PageState.error, retryable: false);
      expect(find.text('Coba lagi'), findsNothing);
    });
  });
}
