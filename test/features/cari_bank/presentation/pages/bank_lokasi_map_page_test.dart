import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/cari_bank/presentation/pages/bank_lokasi_map_page.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _MockUrlLauncher extends Mock
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {}

class _FakeLaunchOptions extends Fake implements LaunchOptions {}

// Same seam contract as the picker: no tile is ever fetched inside a test.
const _noTilesMap = SizedBox.shrink();

void main() {
  late _MockUrlLauncher launcher;

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
    when(() => launcher.launchUrl(any(), any())).thenAnswer((_) async => true);
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BankLokasiMapPage(
          nama: 'Bank Depok Hijau',
          latitude: -6.362829,
          longitude: 106.828655,
          tileLayerBuilder: () => _noTilesMap,
        ),
      ),
    );
  }

  testWidgets('renders the bank pin and name card', (tester) async {
    await pump(tester);

    expect(find.byKey(const Key('detail_bank_marker')), findsOneWidget);
    expect(find.text('Bank Depok Hijau'), findsOneWidget);
  });

  testWidgets('Buka di Maps fires the geo: deeplink carrying point and label',
      (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('detail_bank_buka_di_maps')));
    await tester.pump();

    final captured =
        verify(() => launcher.launchUrl(captureAny(), captureAny())).captured;
    final uri = Uri.parse(captured[0] as String);
    expect(uri.scheme, 'geo');
    expect(
      uri.queryParameters['q'],
      '-6.362829,106.828655(Bank Depok Hijau)',
    );
  });

  testWidgets('a refused launch degrades silently, no crash', (tester) async {
    // launchUrl surfaces "no maps app" as a PlatformException; the page's
    // catch-all must keep the page alive.
    when(() => launcher.launchUrl(any(), any()))
        .thenThrow(Exception('no maps app'));

    await pump(tester);
    await tester.tap(find.byKey(const Key('detail_bank_buka_di_maps')));
    await tester.pump();

    expect(find.byKey(const Key('detail_bank_buka_di_maps')), findsOneWidget);
  });
}
