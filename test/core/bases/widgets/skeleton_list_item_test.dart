import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';

void main() {
  double opacity(WidgetTester tester) =>
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;

  testWidgets('keeps pulsing between full and dimmed while shown',
      (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SkeletonListItem())));
    expect(opacity(tester), 1.0);

    await tester.pump(const Duration(milliseconds: 800));
    expect(opacity(tester), 0.4);

    await tester.pump(const Duration(milliseconds: 800));
    expect(opacity(tester), 1.0);
  });

  testWidgets('stops pulsing once removed', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SkeletonListItem())));
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));

    // No periodic timer is left running after the item is gone.
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
