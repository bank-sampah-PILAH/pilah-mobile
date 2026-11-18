import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/profile/presentation/widgets/legal_information.dart';
import '../../../../support/pump_app.dart';

void main() {
  testWidgets('opens the dedicated legal information page', (tester) async {
    await pumpRouted(
      tester,
      const Scaffold(body: LegalInformationButton()),
      extraRoutes: ['/legal'],
      pushed: true,
    );

    await tester.tap(find.text('Informasi & legal'));
    await tester.pumpAndSettle();

    expect(find.text('route:/legal'), findsOneWidget);
  });
}
