import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_navigation_config.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_navigation_rail.dart';

import '../../support/fake_image_download.dart';
import '../../support/pump_app.dart';

/// A Pengurus only ever acts on behalf of one bank sampah, and every figure on
/// screen belongs to it. On a phone that context sits in the dashboard header,
/// but the rail is visible on every page, so it is the honest place to state
/// which bank sampah the session is operating as.
void main() {
  Future<void> mount(
    WidgetTester tester, {
    String? bankSampahNama,
    String? bankSampahLogoUrl,
    String? role = 'pengelola',
    Size window = const Size(1440, 900),
  }) async {
    await pumpRouted(
      tester,
      Scaffold(
        body: Row(children: [
          RoleNavigationRail(
            navigation: RoleNavigationConfig(
              role: role,
              currentIndex: 0,
              bankSampahNama: bankSampahNama,
              bankSampahLogoUrl: bankSampahLogoUrl,
              onSelected: (_) {},
            ),
          ),
          const Expanded(child: SizedBox.shrink()),
        ]),
      ),
      size: window,
    );
  }

  group('RoleNavigationRail bank sampah context', () {
    testWidgets('names the bank sampah on a desktop window', (tester) async {
      await mount(tester, bankSampahNama: 'Bank Sampah Melati');
      expect(find.text('Bank Sampah Melati'), findsOneWidget);
    });

    testWidgets('falls back to a generic label when the name is missing',
        (tester) async {
      await mount(tester, bankSampahNama: null);
      expect(find.text('Bank Sampah'), findsOneWidget,
          reason: 'a missing name must not leave the header blank');
    });

    testWidgets('treats a blank name as missing', (tester) async {
      await mount(tester, bankSampahNama: '   ');
      expect(find.text('Bank Sampah'), findsOneWidget);
    });

    testWidgets('shortens to initials when the rail is collapsed',
        (tester) async {
      await mount(tester,
          bankSampahNama: 'Bank Sampah Melati', window: const Size(720, 900));
      expect(find.text('Bank Sampah Melati'), findsNothing,
          reason: 'a collapsed rail has no room for the full name');
      expect(find.text('BS'), findsOneWidget);
    });

    testWidgets('shows no header when the role has no navigation',
        (tester) async {
      await mount(tester, role: 'superadmin', bankSampahNama: 'Bank X');
      expect(find.text('Bank X'), findsNothing);
    });

    testWidgets('a long name does not overflow the rail', (tester) async {
      await mount(tester,
          bankSampahNama:
              'Bank Sampah Kelurahan Kukusan Beji Depok Jawa Barat Indonesia');
      expect(tester.takeException(), isNull);
    });

    testWidgets('a stored logo is drawn instead of the initials badge',
        (tester) async {
      final debugImage = FakeImageDownload.install();
      await mount(tester,
          bankSampahNama: 'Bank Sampah Melati',
          bankSampahLogoUrl: 'https://media.test/logo.png');
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      debugImage.finish();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();

      final headers = tester
          .widgetList<Image>(find.byType(Image))
          .where((i) => i.image is NetworkImage)
          .toList();
      expect(headers, isNotEmpty);
      expect((headers.first.image as NetworkImage).url,
          'https://media.test/logo.png');
      FakeImageDownload.uninstall();
    });
  });
}
