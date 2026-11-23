import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/router/app_router_config.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/legal/domain/legal_document.dart';
import 'package:pilah_mobile/features/legal/presentation/pages/legal_document_page.dart';
import 'package:pilah_mobile/features/legal/presentation/pages/legal_information_page.dart';

import '../../support/app_shell_support.dart';
import '../../support/stub_api.dart';

void main() {
  late AppShell shell;

  setUp(() async {
    shell = AppShell(StubApi());
    await shell.registerDi();
    shell.signedInAs(Unauthenticated());
  });

  tearDown(() => shell.unregisterDi());

  testWidgets(
      'legal documents can be read before registration without losing an invite',
      (tester) async {
    shell.invites.save('synthetic-pending-invite');
    final router = AppRouterConfig.getRouter();
    router.go('/legal');
    await tester
        .pumpWidget(shell.wrap(MaterialApp.router(routerConfig: router)));
    await tester.pumpAndSettle();

    expect(find.byType(LegalInformationPage), findsOneWidget);
    await tester.tap(find.text('Kebijakan Privasi'));
    await tester.pumpAndSettle();

    expect(find.byType(LegalDocumentPage), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(
        tester
            .widget<LegalDocumentPage>(find.byType(LegalDocumentPage))
            .document,
        LegalDocument.privacyPolicy);
    expect(shell.invites.token, 'synthetic-pending-invite');

    await tester.tap(find.bySemanticsLabel('Kembali'));
    await tester.pumpAndSettle();
    expect(find.byType(LegalInformationPage), findsOneWidget);
  });

  testWidgets('all document deep links work before session restoration',
      (tester) async {
    shell.signedInAs(AuthenticationInitial());
    final router = AppRouterConfig.getRouter();
    await tester
        .pumpWidget(shell.wrap(MaterialApp.router(routerConfig: router)));
    for (final document in LegalDocument.values) {
      router.go(document.path);
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<LegalDocumentPage>(find.byType(LegalDocumentPage))
              .document,
          document);
    }
  });
}
