import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/bases/widgets/bottom_sheet_header.dart';

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
}
