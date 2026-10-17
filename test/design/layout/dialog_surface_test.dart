import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/layout/dialog_surface.dart';

void main() {
  testWidgets('tells content whether it sits inside a dialog', (tester) async {
    late bool inside;
    late bool outside;
    await tester.pumpWidget(MaterialApp(
      home: Column(children: [
        Builder(builder: (context) {
          outside = DialogSurface.of(context);
          return const SizedBox();
        }),
        DialogSurface(
          child: Builder(builder: (context) {
            inside = DialogSurface.of(context);
            return const SizedBox();
          }),
        ),
      ]),
    ));

    expect(inside, isTrue);
    expect(outside, isFalse);
  });

  testWidgets('survives a rebuild of its surroundings', (tester) async {
    var label = 'one';
    late StateSetter rebuild;
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(builder: (context, setState) {
        rebuild = setState;
        return DialogSurface(child: Text(label));
      }),
    ));

    rebuild(() => label = 'two');
    await tester.pump();

    expect(find.text('two'), findsOneWidget);
  });
}
