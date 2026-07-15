import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';

void main() {
  // Timed against the real clock. Asserting on the widget tree instead would be
  // useless here: RefreshIndicator keeps its spinner mounted through its own
  // retract animation, so it is still findable for a while after the refresh
  // resolves — a tree-based check passes whether or not the hold exists.
  group('withMinimumDuration', () {
    test('holds a 30ms action to the floor so the spinner can be perceived',
        () async {
      final stopwatch = Stopwatch()..start();
      await withMinimumDuration(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
        const Duration(milliseconds: 500),
      );
      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        greaterThanOrEqualTo(490),
        reason: 'a 30ms fetch must not flash by in a couple of frames',
      );
    });

    test('does not stretch an action that already outlasts the floor',
        () async {
      final stopwatch = Stopwatch()..start();
      await withMinimumDuration(
        () => Future<void>.delayed(const Duration(milliseconds: 700)),
        const Duration(milliseconds: 200),
      );
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(690));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(880),
        reason: 'the floor must run alongside the fetch, not be added to it',
      );
    });

    test('propagates a failure rather than swallowing it', () async {
      await expectLater(
        withMinimumDuration(
          () => Future<void>.error(StateError('fetch blew up')),
          const Duration(milliseconds: 50),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('AppRefreshIndicator', () {
    testWidgets('a pull runs onRefresh exactly once', (tester) async {
      var calls = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppRefreshIndicator(
            onRefresh: () async => calls++,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [SizedBox(height: 80, child: Text('item'))],
            ),
          ),
        ),
      ));

      await tester.fling(find.text('item'), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(calls, 1);
    });

    testWidgets('applies the 500ms floor to whatever it is given',
        (tester) async {
      expect(AppRefreshIndicator.minimumSpinnerHold,
          const Duration(milliseconds: 500));
    });
  });
}
