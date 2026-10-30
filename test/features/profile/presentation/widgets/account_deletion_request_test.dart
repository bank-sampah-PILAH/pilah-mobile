import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pilah_mobile/features/profile/presentation/widgets/account_deletion_request.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _MockUrlLauncher extends Mock
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {}

class _FakeLaunchOptions extends Fake implements LaunchOptions {}

void main() {
  late UrlLauncherPlatform original;
  late _MockUrlLauncher launcher;

  setUpAll(() {
    registerFallbackValue(_FakeLaunchOptions());
    registerFallbackValue(PreferredLaunchMode.externalApplication);
  });

  setUp(() {
    original = UrlLauncherPlatform.instance;
    launcher = _MockUrlLauncher();
    UrlLauncherPlatform.instance = launcher;
  });

  tearDown(() => UrlLauncherPlatform.instance = original);

  Future<void> openButton(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: AccountDeletionRequestButton()),
    ));
  }

  testWidgets('opens the public account deletion information', (tester) async {
    when(() => launcher.launchUrl(any(), any())).thenAnswer((_) async => true);
    await openButton(tester);

    await tester.tap(find.text('Permintaan penghapusan akun'));
    await tester.pump();

    verify(() => launcher.launchUrl(
        'https://sites.google.com/view/pilah-privacy-policy', any())).called(1);
  });

  testWidgets('shows an error when the page cannot be opened', (tester) async {
    when(() => launcher.launchUrl(any(), any())).thenAnswer((_) async => false);
    await openButton(tester);

    await tester.tap(find.text('Permintaan penghapusan akun'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
        find.text(
            'Halaman informasi tidak dapat dibuka. Periksa koneksi Anda dan coba lagi.'),
        findsOneWidget);
  });

  testWidgets('shows an error when the platform cannot launch the page',
      (tester) async {
    when(() => launcher.launchUrl(any(), any()))
        .thenThrow(PlatformException(code: 'ACTIVITY_NOT_FOUND'));
    await openButton(tester);

    await tester.tap(find.text('Permintaan penghapusan akun'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
        find.text(
            'Halaman informasi tidak dapat dibuka. Periksa koneksi Anda dan coba lagi.'),
        findsOneWidget);
  });
}
