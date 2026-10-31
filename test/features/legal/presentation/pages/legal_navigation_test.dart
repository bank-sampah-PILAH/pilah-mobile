import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/legal/domain/legal_document.dart';
import 'package:pilah_mobile/features/legal/presentation/pages/legal_document_page.dart';
import 'package:pilah_mobile/features/legal/presentation/pages/legal_information_page.dart';

import '../../../../support/pump_app.dart';

void main() {
  testWidgets('back from legal information returns to the previous screen',
      (tester) async {
    await pumpRouted(tester, const LegalInformationPage(), pushed: true);

    await tester.tap(find.bySemanticsLabel('Kembali'));
    await tester.pumpAndSettle();

    expect(find.text('route:/'), findsOneWidget);
    expect(find.byType(LegalInformationPage), findsNothing);
  });

  testWidgets('back from a document deep link returns through the hub to login',
      (tester) async {
    final document = LegalDocument.termsAndConditions;
    final router = GoRouter(
      initialLocation: document.path,
      routes: [
        GoRoute(
          path: document.path,
          builder: (_, __) => LegalDocumentPage(document: document),
        ),
        GoRoute(
          path: LegalInformationPage.route,
          builder: (_, __) => const LegalInformationPage(),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => const Scaffold(body: Text('Login destination')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.byType(LegalDocumentPage), findsOneWidget);
    expect(router.canPop(), isFalse);

    await tester.tap(find.bySemanticsLabel('Kembali'));
    await tester.pumpAndSettle();
    expect(find.byType(LegalInformationPage), findsOneWidget);
    expect(router.canPop(), isFalse);

    await tester.tap(find.bySemanticsLabel('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Login destination'), findsOneWidget);
    expect(find.byType(LegalInformationPage), findsNothing);
  });
}
