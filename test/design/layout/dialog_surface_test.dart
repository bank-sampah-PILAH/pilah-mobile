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

  group('keyboardInset', () {
    Future<double> measure(WidgetTester tester,
        {required bool inDialog}) async {
      late double inset;
      final probe = Builder(builder: (context) {
        inset = DialogSurface.keyboardInset(context);
        return const SizedBox();
      });
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 300)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: inDialog ? DialogSurface(child: probe) : probe,
        ),
      ));
      return inset;
    }

    testWidgets('lifts a sheet by the keyboard height', (tester) async {
      expect(await measure(tester, inDialog: false), 300);
    });

    testWidgets('is zero in a dialog, which already moves itself',
        (tester) async {
      expect(await measure(tester, inDialog: true), 0);
    });
  });
}
