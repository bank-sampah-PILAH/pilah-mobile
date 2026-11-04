import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/analytics/analytics_consent_store.dart';
import 'package:pilah_mobile/features/analytics/presentation/providers/analytics_consent_provider.dart';
import 'package:pilah_mobile/features/analytics/presentation/providers/analytics_client_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:pilah_mobile/features/profile/presentation/providers/profile_provider.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/fake_analytics_client.dart';
import '../../../../support/fake_app_storage.dart';
import '../../../../support/profile_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

void main() {
  late StubApi api;
  late FakeAnalyticsClient client;
  late TestProfileNotifier notifier;

  setUp(() {
    api = StubApi();
    stubProfile(api);
    client = FakeAnalyticsClient();
  });

  Future<void> openPage(WidgetTester tester) async {
    notifier = buildProfileNotifier(api);
    final auth = authNotifierIn(Authenticated(authEntity: testAuth()));
    await pumpRouted(
      tester,
      const ProfilePage(),
      extraRoutes: ['/login'],
      providerScopeBuilder: (app) => ProviderScope(
        overrides: [
          profileProvider.overrideWith(() => notifier),
          authenticationProvider.overrideWith(() => auth),
          analyticsClientProvider.overrideWithValue(client),
          analyticsConsentStoreProvider
              .overrideWithValue(AnalyticsConsentStore(FakeAppStorage())),
        ],
        child: app,
      ),
      size: const Size(800, 2400),
      pushed: true,
    );
    await tester.pumpAndSettle();
  }

  List<String> names() => client.events.map((e) => e.name).toList();

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Simpan Pengaturan'));
    await pumpToast(tester);
  }

  group('saving the settings', () {
    testWidgets('names the bank field that changed, not its new value',
        (tester) async {
      api.on('PUT', '/api/v1/bank-sampah/me',
          json: {...bankJson(), 'nama': 'Nama Baru'});
      api.on('PUT', '/api/v1/pengaturan/wa-template', json: {});
      await openPage(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'Nama Baru');
      await tester.pump();
      await save(tester);

      expect(names(), ['profil_pengaturan_disimpan']);
      expect(client.events.single.properties, {
        'bidang_diubah': ['nama_bank'],
      });
      await settleToasts(tester);
    });

    testWidgets('names the template when only the template changed',
        (tester) async {
      api.on('PUT', '/api/v1/bank-sampah/me', json: bankJson());
      api.on('PUT', '/api/v1/pengaturan/wa-template', json: {});
      await openPage(tester);
      await tester.scrollUntilVisible(find.text('{Nama}'), 300,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('{Nama}'));
      await tester.pump();

      await save(tester);

      expect(client.events.single.properties, {
        'bidang_diubah': ['template_wa'],
      });
      await settleToasts(tester);
    });

    testWidgets('names the logo when a new one was picked', (tester) async {
      api.on('PUT', '/api/v1/bank-sampah/me', json: bankJson());
      api.on('PUT', '/api/v1/pengaturan/wa-template', json: {});
      await openPage(tester);
      notifier.setStateForTest(notifier.state.copyWith(
        selectedLogoBytes: Uint8List.fromList([1, 2, 3]),
        selectedLogoFilename: 'logo.png',
      ));
      await tester.pumpAndSettle();

      await save(tester);

      expect(client.events.single.properties, {
        'bidang_diubah': ['logo'],
      });
      await settleToasts(tester);
    });

    testWidgets('names every field changed in the one save', (tester) async {
      api.on('PUT', '/api/v1/bank-sampah/me', json: bankJson());
      api.on('PUT', '/api/v1/pengaturan/wa-template', json: {});
      await openPage(tester);
      await tester.enterText(find.byType(TextFormField).at(0), 'Nama Baru');
      await tester.enterText(find.byType(TextFormField).at(1), 'Jl. Baru 1');
      await tester.pump();

      await save(tester);

      expect(client.events.single.properties['bidang_diubah'],
          ['nama_bank', 'alamat']);
      await settleToasts(tester);
    });

    testWidgets('sends nothing when the bank update is rejected',
        (tester) async {
      api.on('PUT', '/api/v1/bank-sampah/me', status: 422, json: {
        'errors': {
          'no_hp_pic': ['Nomor tidak valid']
        }
      });
      await openPage(tester);
      await tester.enterText(find.byType(TextFormField).at(0), 'Nama Baru');
      await tester.pump();

      await save(tester);

      expect(client.events, isEmpty);
      await settleToasts(tester);
    });

    testWidgets('sends nothing when the template is rejected', (tester) async {
      api.on('PUT', '/api/v1/bank-sampah/me', json: bankJson());
      api.on('PUT', '/api/v1/pengaturan/wa-template', status: 422, json: {
        'errors': {
          'template': ['Template kosong']
        }
      });
      await openPage(tester);
      await tester.enterText(find.byType(TextFormField).at(0), 'Nama Baru');
      await tester.pump();

      await save(tester);

      expect(client.events, isEmpty);
      await settleToasts(tester);
    });
  });

  group('the invite link', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
    });
    tearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    testWidgets('copying it is reported', (tester) async {
      api.on('POST', '/api/v1/team/invite',
          json: {'invite_url': 'https://pilah.test/invite/abc'});
      await openPage(tester);
      await tester.tap(find.text('Manajemen Tim'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salin Link Undangan'));
      await pumpToast(tester);

      expect(names(), ['undangan_tautan_disalin']);
      expect(client.events.single.properties, isEmpty);
      await settleToasts(tester);
    });

    testWidgets('a refused invite is not reported', (tester) async {
      api.on('POST', '/api/v1/team/invite',
          status: 403, json: {'error': 'Hanya pengelola utama'});
      await openPage(tester);
      await tester.tap(find.text('Manajemen Tim'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salin Link Undangan'));
      await pumpToast(tester);

      expect(client.events, isEmpty);
      await settleToasts(tester);
    });
  });
}
