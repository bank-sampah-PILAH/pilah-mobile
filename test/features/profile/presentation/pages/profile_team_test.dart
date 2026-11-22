import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:pilah_mobile/features/profile/presentation/providers/profile_provider.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/profile_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

Map<String, dynamic> member(
  String id,
  String nama, {
  bool primary = false,
  bool me = false,
}) =>
    {
      'id': id,
      'nama': nama,
      'email': '$nama@x.test',
      'is_primary_pengelola': primary,
      'is_current_user': me,
    };

void main() {
  late StubApi api;
  late TestProfileNotifier notifier;
  late TestAuthenticationNotifier auth;

  setUp(() {
    api = StubApi();
    notifier = buildProfileNotifier(api);
    auth = authNotifierIn(Authenticated(authEntity: testAuth()));
  });

  void stubTeam({required bool iAmPrimary}) {
    stubProfile(api, team: {
      'members': [
        member('u1', 'Siti', primary: iAmPrimary, me: true),
        member('u2', 'Andi', primary: !iAmPrimary),
        member('u3', 'Budi'),
      ],
    });
  }

  Future<void> openTeamTab(
    WidgetTester tester, {
    Size size = const Size(390, 2400),
    bool? isWeb,
  }) async {
    await pumpRouted(
      tester,
      ProfilePage(isWeb: isWeb),
      extraRoutes: const ['/login'],
      providerScopeBuilder: (app) => ProviderScope(
        overrides: [
          profileProvider.overrideWith(() => notifier),
          authenticationProvider.overrideWith(() => auth),
        ],
        child: app,
      ),
      size: size,
      pushed: true,
    );
    await tester.pumpAndSettle();
    // At a phone width in the browser the tab sits at the edge of the bar.
    await tester.ensureVisible(find.text('Manajemen Tim'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manajemen Tim'));
    await tester.pumpAndSettle();
  }

  /// Lets the screen settle without running out the toast's own timer.
  Future<void> settleKeepingToast(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  final menus = find.byWidgetPredicate((w) => w is PopupMenuButton);

  /// The row menus are keyed by the member they act on.
  Future<void> openMenuOf(WidgetTester tester, String id) async {
    await tester.tap(find.byKey(ValueKey('team-menu-$id')));
    await tester.pumpAndSettle();
  }

  for (final (label, size, isWeb) in [
    ('phone', const Size(390, 2400), false),
    ('web phone width', const Size(390, 2400), true),
    ('web desktop', const Size(1440, 1000), true),
  ]) {
    group('hand over the Pengurus Utama role on $label', () {
      testWidgets('only the Pengurus Utama gets the action on others',
          (tester) async {
        stubTeam(iAmPrimary: true);
        await openTeamTab(tester, size: size, isWeb: isWeb);

        // Two other pengurus, no menu on the signed-in row.
        expect(menus, findsNWidgets(2));
        await openMenuOf(tester, 'u2');
        expect(find.text('Jadikan Pengurus Utama'), findsOneWidget);
      });

      testWidgets('a regular pengurus has no action at all', (tester) async {
        stubTeam(iAmPrimary: false);
        await openTeamTab(tester, size: size, isWeb: isWeb);

        expect(menus, findsNothing);
      });

      testWidgets('confirming transfers and flips what the screen shows',
          (tester) async {
        stubTeam(iAmPrimary: true);
        await openTeamTab(tester, size: size, isWeb: isWeb);
        expect(find.text('Undang Pengurus Baru'), findsOneWidget);
        api.on('POST', '/api/v1/team/transfer', json: {
          'members': [
            member('u2', 'Andi', primary: true),
            member('u1', 'Siti', me: true),
            member('u3', 'Budi'),
          ],
        });

        await openMenuOf(tester, 'u2');
        await tester.tap(find.text('Jadikan Pengurus Utama'));
        await tester.pumpAndSettle();
        expect(find.text('Jadikan Andi Pengurus Utama?'), findsOneWidget);
        expect(find.textContaining('Anda akan menjadi pengurus biasa'),
            findsOneWidget);
        await tester.tap(find.text('Ya, Jadikan'));
        await settleKeepingToast(tester);

        expect(api.last.method, 'POST');
        expect(api.last.path, '/api/v1/team/transfer');
        expect(api.last.json, {'id': 'u2'});
        expect(auth.calls, contains('refreshUser'));
        expect(find.text('Undang Pengurus Baru'), findsNothing);
        expect(menus, findsNothing);
        expect(find.text('Jabatan Pengurus Utama dialihkan ke Andi'),
            findsOneWidget);
      });

      testWidgets('cancelling changes nothing', (tester) async {
        stubTeam(iAmPrimary: true);
        await openTeamTab(tester, size: size, isWeb: isWeb);

        await openMenuOf(tester, 'u2');
        await tester.tap(find.text('Jadikan Pengurus Utama'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();

        expect(api.requests.where((r) => r.method == 'POST'), isEmpty);
        expect(auth.calls, isNot(contains('refreshUser')));
        expect(find.text('Undang Pengurus Baru'), findsOneWidget);
      });
    });
  }

  testWidgets('a refused transfer says why and keeps the roster',
      (tester) async {
    stubTeam(iAmPrimary: true);
    await openTeamTab(tester);
    api.on('POST', '/api/v1/team/transfer',
        status: 403, json: {'error': 'Pengurus tidak ditemukan'});

    await openMenuOf(tester, 'u2');
    await tester.tap(find.text('Jadikan Pengurus Utama'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya, Jadikan'));
    await settleKeepingToast(tester);

    expect(find.text('Pengurus tidak ditemukan'), findsOneWidget);
    expect(find.text('Undang Pengurus Baru'), findsOneWidget);
    expect(auth.calls, isNot(contains('refreshUser')));
  });

  for (final (label, size, isWeb) in [
    ('phone', const Size(390, 2400), false),
    ('web phone width', const Size(390, 2400), true),
    ('web desktop', const Size(1440, 1000), true),
  ]) {
    group('remove a pengurus on $label', () {
      testWidgets('the menu offers it next to the hand-over', (tester) async {
        stubTeam(iAmPrimary: true);
        await openTeamTab(tester, size: size, isWeb: isWeb);

        await openMenuOf(tester, 'u3');

        expect(find.text('Jadikan Pengurus Utama'), findsOneWidget);
        expect(find.text('Keluarkan'), findsOneWidget);
      });

      testWidgets('confirming deletes them and the row goes', (tester) async {
        stubTeam(iAmPrimary: true);
        await openTeamTab(tester, size: size, isWeb: isWeb);
        api.on('DELETE', '/api/v1/team/u3', status: 204, json: null);

        await openMenuOf(tester, 'u3');
        await tester.tap(find.text('Keluarkan'));
        await tester.pumpAndSettle();
        expect(find.text('Keluarkan Budi dari tim?'), findsOneWidget);
        expect(
            find.textContaining('tidak bisa lagi mengakses'), findsOneWidget);
        await tester.tap(find.text('Ya, Keluarkan'));
        await settleKeepingToast(tester);

        expect(api.last.method, 'DELETE');
        expect(api.last.path, '/api/v1/team/u3');
        expect(find.text('Budi'), findsNothing);
        expect(find.text('Budi dikeluarkan dari tim'), findsOneWidget);
        expect(menus, findsOneWidget);
      });

      testWidgets('cancelling deletes nothing', (tester) async {
        stubTeam(iAmPrimary: true);
        await openTeamTab(tester, size: size, isWeb: isWeb);

        await openMenuOf(tester, 'u3');
        await tester.tap(find.text('Keluarkan'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();

        expect(api.requests.where((r) => r.method == 'DELETE'), isEmpty);
        expect(find.text('Budi'), findsOneWidget);
      });
    });
  }

  testWidgets('a refused removal says why and keeps the row', (tester) async {
    stubTeam(iAmPrimary: true);
    await openTeamTab(tester);
    api.on('DELETE', '/api/v1/team/u3',
        status: 403, json: {'error': 'Pengurus ini tidak bisa dikeluarkan'});

    await openMenuOf(tester, 'u3');
    await tester.tap(find.text('Keluarkan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya, Keluarkan'));
    await settleKeepingToast(tester);

    expect(find.text('Pengurus ini tidak bisa dikeluarkan'), findsOneWidget);
    expect(find.text('Budi'), findsOneWidget);
  });

  const inviteNote = 'Hanya Pengurus Utama yang bisa mengundang pengurus baru.';

  for (final (label, size, isWeb) in [
    ('phone', const Size(390, 2400), false),
    ('web phone width', const Size(390, 2400), true),
    ('web desktop', const Size(1440, 1000), true),
  ]) {
    group('invitations are for the Pengurus Utama on $label', () {
      testWidgets('a regular pengurus gets a short note and no invitation',
          (tester) async {
        stubTeam(iAmPrimary: false);
        await openTeamTab(tester, size: size, isWeb: isWeb);

        expect(find.text(inviteNote), findsOneWidget);
        expect(find.text('Undang Pengurus Baru'), findsNothing);
        expect(find.text('Buat Link Undangan'), findsNothing);
        expect(
          api.requests.where((r) => r.path == '/api/v1/team/invite'),
          isEmpty,
        );
      });

      testWidgets('the Pengurus Utama has the invitation, not the note',
          (tester) async {
        stubTeam(iAmPrimary: true);
        await openTeamTab(tester, size: size, isWeb: isWeb);

        expect(find.text('Undang Pengurus Baru'), findsOneWidget);
        expect(find.text(inviteNote), findsNothing);
      });

      testWidgets('handing over the role swaps the invitation for the note',
          (tester) async {
        stubTeam(iAmPrimary: true);
        await openTeamTab(tester, size: size, isWeb: isWeb);
        api.on('POST', '/api/v1/team/transfer', json: {
          'members': [
            member('u2', 'Andi', primary: true),
            member('u1', 'Siti', me: true),
            member('u3', 'Budi'),
          ],
        });

        await openMenuOf(tester, 'u2');
        await tester.tap(find.text('Jadikan Pengurus Utama'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ya, Jadikan'));
        await settleKeepingToast(tester);

        expect(find.text(inviteNote), findsOneWidget);
        expect(find.text('Undang Pengurus Baru'), findsNothing);
      });
    });
  }

  testWidgets('a roster that did not load shows neither', (tester) async {
    stubProfile(api, team: {'members': []});
    await openTeamTab(tester);

    expect(find.text(inviteNote), findsNothing);
    expect(find.text('Undang Pengurus Baru'), findsNothing);
  });

  testWidgets('a stale screen learns the role moved when the server refuses',
      (tester) async {
    stubTeam(iAmPrimary: true);
    await openTeamTab(tester);
    api.on('POST', '/api/v1/team/invite', status: 403, json: {
      'error': 'Hanya Pengurus Utama yang bisa membuat tautan undangan',
    });
    stubTeam(iAmPrimary: false);

    await tester.tap(find.text('Buat Link Undangan'));
    await settleKeepingToast(tester);

    expect(find.text('Hanya Pengurus Utama yang bisa membuat tautan undangan'),
        findsOneWidget);
    expect(find.text(inviteNote), findsOneWidget);
    expect(find.text('Undang Pengurus Baru'), findsNothing);
  });
}
