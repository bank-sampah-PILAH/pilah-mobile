import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/transaksi/domain/wa_deeplink.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _MockUrlLauncher extends Mock
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {}

class _FakeLaunchOptions extends Fake implements LaunchOptions {}

/// Covers the hand-off between [buildWaSetoranLink] and `url_launcher`.
///
/// The unit tests in `wa_deeplink_test.dart` assert the [Uri] we build; these
/// assert that what the platform channel finally receives is still that link.
/// The step in between is `url.toString()`, which is where a percent-encoded
/// query could plausibly be re-normalized and lose the escaped newlines.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockUrlLauncher launcher;

  final waLink = buildWaSetoranLink(
    phone: '0812-3456-7890',
    nama: 'Budi Susanto',
    items: const [
      WaSetoranItem(namaSampah: 'Plastik PET', berat: 5.2),
      WaSetoranItem(namaSampah: 'Kertas kardus', berat: 2.0),
    ],
  );

  setUpAll(() {
    registerFallbackValue(_FakeLaunchOptions());
    registerFallbackValue(PreferredLaunchMode.externalApplication);
  });

  setUp(() {
    launcher = _MockUrlLauncher();
    UrlLauncherPlatform.instance = launcher;
    when(() => launcher.supportsMode(any())).thenAnswer((_) async => true);
    when(() => launcher.supportsCloseForMode(any()))
        .thenAnswer((_) async => false);
  });

  test('the link reaches the platform intact, as an external app launch',
      () async {
    when(() => launcher.launchUrl(any(), any())).thenAnswer((_) async => true);

    final opened =
        await launchUrl(waLink, mode: LaunchMode.externalApplication);

    expect(opened, isTrue);
    final captured =
        verify(() => launcher.launchUrl(captureAny(), captureAny())).captured;

    expect(captured[0], waLink.toString());
    expect(
      captured[0] as String,
      contains('https://wa.me/6281234567890?text='),
    );
    expect(
      captured[0] as String,
      contains('%0A'),
      reason: 'the escaped line breaks must survive Uri.toString()',
    );
    expect(
      (captured[1] as LaunchOptions).mode,
      PreferredLaunchMode.externalApplication,
      reason: 'an in-app webview cannot hand the link to WhatsApp',
    );
  });

  test('a device with nowhere to send the link reports false, not a crash',
      () async {
    when(() => launcher.launchUrl(any(), any())).thenAnswer((_) async => false);

    expect(
        await launchUrl(waLink, mode: LaunchMode.externalApplication), isFalse);
  });

  test('a refused intent throws, which is why the caller wraps it in try/catch',
      () async {
    // What Android raises when no activity can view the link — the page turns
    // this into the "WhatsApp tidak dapat dibuka" warning rather than letting
    // it reach the user as a crash.
    when(() => launcher.launchUrl(any(), any()))
        .thenThrow(PlatformException(code: 'ACTIVITY_NOT_FOUND'));

    expect(
      () => launchUrl(waLink, mode: LaunchMode.externalApplication),
      throwsA(isA<PlatformException>()),
    );
  });
}
