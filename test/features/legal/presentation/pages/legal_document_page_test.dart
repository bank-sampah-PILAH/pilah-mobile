import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pilah_mobile/features/legal/domain/legal_document.dart';
import 'package:pilah_mobile/features/legal/presentation/pages/legal_document_page.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _MockUrlLauncher extends Mock
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {}

class _FakeLaunchOptions extends Fake implements LaunchOptions {}

void main() {
  late UrlLauncherPlatform original;
  late _MockUrlLauncher launcher;

  setUpAll(() => registerFallbackValue(_FakeLaunchOptions()));
  setUp(() {
    original = UrlLauncherPlatform.instance;
    launcher = _MockUrlLauncher();
    UrlLauncherPlatform.instance = launcher;
  });
  tearDown(() => UrlLauncherPlatform.instance = original);

  Future<void> openDeletion(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: LegalDocumentPage(document: LegalDocument.accountDeletion),
    ));
    await tester.ensureVisible(find.text('Kirim email permintaan'));
  }

  testWidgets(
      'deletion requests open email with the support address and subject',
      (tester) async {
    when(() => launcher.launchUrl(any(), any())).thenAnswer((_) async => true);
    await openDeletion(tester);
    await tester.tap(find.text('Kirim email permintaan'));
    await tester.pumpAndSettle();
    verify(() => launcher.launchUrl(
          'mailto:banksampahpilah@gmail.com?subject=Permintaan%20penghapusan%20akun%20PILAH',
          any(),
        )).called(1);
  });

  for (final throws in [false, true]) {
    testWidgets(
        'shows the manual email fallback when launch ${throws ? 'throws' : 'fails'}',
        (tester) async {
      if (throws) {
        when(() => launcher.launchUrl(any(), any()))
            .thenThrow(PlatformException(code: 'ACTIVITY_NOT_FOUND'));
      } else {
        when(() => launcher.launchUrl(any(), any()))
            .thenAnswer((_) async => false);
      }
      await openDeletion(tester);
      await tester.tap(find.text('Kirim email permintaan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Kirim permintaan ke banksampahpilah@gmail.com.'),
          findsOneWidget);
    });
  }
}
