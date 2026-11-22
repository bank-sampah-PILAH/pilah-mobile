import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:pilah_mobile/features/profile/presentation/providers/profile_provider.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/profile_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

/// The invitation banner is dark green. A button drawn in the stock outlined
/// style puts green text and a green outline on it, so it cannot be seen
/// although it is there (a merge once dropped the fix for this). The buttons
/// on the banner have to be drawn for a dark surface.
void main() {
  late StubApi api;
  late TestProfileNotifier notifier;

  setUp(() {
    api = StubApi();
    stubProfile(api);
    notifier = buildProfileNotifier(api);
  });

  Future<void> openTeamTab(WidgetTester tester) async {
    await pumpRouted(
      tester,
      const ProfilePage(),
      extraRoutes: const ['/login'],
      providerScopeBuilder: (app) => ProviderScope(
        overrides: [
          profileProvider.overrideWith(() => notifier),
          authenticationProvider.overrideWith(
              () => authNotifierIn(Authenticated(authEntity: testAuth()))),
        ],
        child: app,
      ),
      size: const Size(390, 2400),
      pushed: true,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manajemen Tim'));
    await tester.pumpAndSettle();
  }

  AppButton button(WidgetTester tester, String label) =>
      tester.widget<AppButton>(find.widgetWithText(AppButton, label));

  /// The colour the label is drawn in, resolved from the button's own style.
  Color? labelColor(WidgetTester tester, String label) {
    final outlined = tester.widget<OutlinedButton>(find.descendant(
      of: find.widgetWithText(AppButton, label),
      matching: find.byType(OutlinedButton),
    ));
    return outlined.style?.foregroundColor?.resolve({});
  }

  testWidgets('"Buat Link Undangan" is drawn for the dark banner',
      (tester) async {
    await openTeamTab(tester);

    expect(button(tester, 'Buat Link Undangan').variant,
        AppButtonVariant.outlinedOnDark);
    expect(labelColor(tester, 'Buat Link Undangan'), Colors.white);
  });

  testWidgets('"Coba Lagi" on the banner is drawn for the dark banner',
      (tester) async {
    api.on('GET', '/api/v1/team/invite',
        status: 500, json: {'error': 'Gagal memuat'});
    await openTeamTab(tester);

    expect(
        button(tester, 'Coba Lagi').variant, AppButtonVariant.outlinedOnDark);
  });

  testWidgets('"Buat Link Baru" stays visible on the banner', (tester) async {
    api.on('GET', '/api/v1/team/invite', json: {
      'token': 't',
      'invite_url': 'https://pilah.test/invite/t',
      'expires_at': '2999-01-01T00:00:00Z',
    });
    await openTeamTab(tester);

    // A white button with dark text: it has its own surface.
    expect(button(tester, 'Buat Link Baru').variant, AppButtonVariant.neutral);
  });

  testWidgets('"Buat Link Baru" for an expired link has its own surface too',
      (tester) async {
    api.on('GET', '/api/v1/team/invite', json: {
      'token': 't',
      'invite_url': 'https://pilah.test/invite/t',
      'expires_at': '2000-01-01T00:00:00Z',
    });
    await openTeamTab(tester);

    expect(button(tester, 'Buat Link Baru').variant, AppButtonVariant.tonal);
  });
}
