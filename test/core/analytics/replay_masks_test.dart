import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/analytics/replay_masks.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/design/widgets/app_field_label.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

void main() {
  testWidgets('RevealInReplay unmasks and HideInReplay masks its child', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            RevealInReplay(child: Text('tampil')),
            HideInReplay(child: Text('tersembunyi')),
          ],
        ),
      ),
    );

    expect(find.byType(PostHogUnmaskWidget), findsOneWidget);
    expect(find.byType(PostHogMaskWidget), findsOneWidget);
    expect(find.text('tampil'), findsOneWidget);
    expect(find.text('tersembunyi'), findsOneWidget);
  });

  testWidgets('field captions and button labels are revealed in the recording',
      (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            const AppFieldLabel('NAMA LENGKAP'),
            AppButton(label: 'Simpan', onPressed: () {}),
          ],
        ),
      ),
    );

    expect(
      find.ancestor(
        of: find.text('NAMA LENGKAP'),
        matching: find.byType(RevealInReplay),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.text('Simpan'),
        matching: find.byType(RevealInReplay),
      ),
      findsOneWidget,
    );
  });
}
