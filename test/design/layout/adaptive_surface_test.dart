import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/layout/adaptive_surface.dart';
import 'package:pilah_mobile/design/layout/dialog_surface.dart';

void main() {
  Future<void> open(WidgetTester tester, Size size,
      {required void Function(bool inDialog) report}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showAdaptiveSurface<void>(
              context,
              builder: (surface) {
                report(DialogSurface.of(surface));
                return const SizedBox(height: 40, child: Text('isi'));
              },
            ),
            child: const Text('buka'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
  }

  testWidgets('a phone gets a bottom sheet, and the content knows it',
      (tester) async {
    bool? inDialog;
    await open(tester, const Size(390, 844), report: (v) => inDialog = v);

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(inDialog, isFalse);
  });

  testWidgets('a wide window gets a dialog, and the content knows it',
      (tester) async {
    bool? inDialog;
    await open(tester, const Size(1200, 800), report: (v) => inDialog = v);

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(inDialog, isTrue,
        reason: 'the builder context sits below DialogSurface, so a sheet '
            'that draws its own card can skip it inside a dialog');
  });
}
