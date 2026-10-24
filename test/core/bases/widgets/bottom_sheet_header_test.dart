import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/bases/widgets/bottom_sheet_header.dart';
import 'package:pilah_mobile/design/layout/dialog_surface.dart';

import '../../../support/pump_app.dart';

void main() {
  testWidgets('shows its title and the close button goes back', (tester) async {
    await pumpRouted(
      tester,
      const Scaffold(body: BottomSheetHeader(title: 'Pilih Nasabah')),
      pushed: true,
    );
    expect(find.text('Pilih Nasabah'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Pilih Nasabah'), findsNothing);
    expect(find.text('route:/'), findsOneWidget);
  });

  group('the drag handle', () {
    Future<void> mount(WidgetTester tester, Widget header) =>
        tester.pumpWidget(MaterialApp(home: Scaffold(body: header)));

    testWidgets('shows by default', (tester) async {
      await mount(tester, const BottomSheetHeader(title: 'Judul'));
      expect(find.byKey(BottomSheetHeader.dragHandleKey), findsOneWidget);
    });

    testWidgets('is left out inside a dialog, which cannot be dragged',
        (tester) async {
      await mount(tester,
          const DialogSurface(child: BottomSheetHeader(title: 'Judul')));
      expect(find.byKey(BottomSheetHeader.dragHandleKey), findsNothing);
    });

    testWidgets('can be forced either way', (tester) async {
      await mount(tester,
          const BottomSheetHeader(title: 'Judul', showDragHandle: false));
      expect(find.byKey(BottomSheetHeader.dragHandleKey), findsNothing);

      await mount(
          tester,
          const DialogSurface(
              child: BottomSheetHeader(title: 'Judul', showDragHandle: true)));
      expect(find.byKey(BottomSheetHeader.dragHandleKey), findsOneWidget);
    });
  });
}
