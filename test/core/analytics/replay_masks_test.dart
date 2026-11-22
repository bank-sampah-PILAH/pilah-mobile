import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/analytics/replay_masks.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

void main() {
  group('replayTextMask', () {
    testWidgets('shows icons and hides every other text', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Column(children: [
          Icon(Icons.home),
          Icon(CupertinoIcons.back),
          Text('Budi Santoso'),
        ]),
      ));
      RichText richOf(Finder f) => tester.widget<RichText>(
          find.descendant(of: f, matching: find.byType(RichText)));

      expect(
        replayTextMask('', richOf(find.byIcon(Icons.home))),
        isA<PostHogTextMaskNone>(),
      );
      expect(
        replayTextMask('', richOf(find.byIcon(CupertinoIcons.back))),
        isA<PostHogTextMaskNone>(),
      );
      expect(
        replayTextMask('Budi Santoso', richOf(find.text('Budi Santoso'))),
        isA<PostHogTextMaskAll>(),
      );
    });

    test('hides a widget that is not text', () {
      expect(replayTextMask('x', const SizedBox()), isA<PostHogTextMaskAll>());
    });
  });
}
