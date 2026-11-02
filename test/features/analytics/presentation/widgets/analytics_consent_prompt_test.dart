import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/analytics/analytics_consent_store.dart';
import 'package:pilah_mobile/design/theme/app_theme.dart';
import 'package:pilah_mobile/features/analytics/presentation/providers/analytics_consent_provider.dart';
import 'package:pilah_mobile/features/analytics/presentation/widgets/analytics_consent_prompt.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/fake_analytics_client.dart';
import '../../../../support/fake_app_storage.dart';

const _title = 'Bantu kami memperbaiki PILAH';

Authenticated _signedInAs(String role) => Authenticated(
      authEntity: AuthEntity(
        name: 'Tester',
        email: 'tester@example.com',
        photoUrl: '',
        token: 'token',
        role: role,
      ),
    );

void main() {
  late FakeAppStorage storage;
  late FakeAnalyticsClient client;
  var role = 'pengelola';

  setUp(() {
    storage = FakeAppStorage();
    client = FakeAnalyticsClient();
    role = 'pengelola';
  });

  Future<void> openApp(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authenticationProvider.overrideWith(
            () => TestAuthenticationNotifier(initialState: _signedInAs(role))),
        analyticsClientProvider.overrideWithValue(client),
        analyticsConsentStoreProvider
            .overrideWithValue(AnalyticsConsentStore(storage)),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const AnalyticsConsentPrompt(
          child: Scaffold(body: Text('beranda')),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('asks a pengurus who has not chosen yet', (tester) async {
    await openApp(tester);

    expect(find.text(_title), findsOneWidget);
    expect(find.text('beranda'), findsOneWidget);
  });

  testWidgets('agreeing starts recording and is not asked again',
      (tester) async {
    await openApp(tester);

    await tester.tap(find.text('Setuju'));
    await tester.pumpAndSettle();

    expect(client.calls, ['start']);
    expect(await AnalyticsConsentStore(storage).read(), ConsentChoice.granted);
    expect(find.text(_title), findsNothing);
  });

  testWidgets('declining records nothing and is not asked again',
      (tester) async {
    await openApp(tester);

    await tester.tap(find.text('Tolak'));
    await tester.pumpAndSettle();

    expect(client.calls, isEmpty);
    expect(await AnalyticsConsentStore(storage).read(), ConsentChoice.denied);
    expect(find.text(_title), findsNothing);
  });

  testWidgets('does not ask a nasabah', (tester) async {
    role = 'nasabah';

    await openApp(tester);

    expect(find.text(_title), findsNothing);
    expect(find.text('beranda'), findsOneWidget);
  });

  testWidgets('does not ask someone who already answered', (tester) async {
    await AnalyticsConsentStore(storage).deny();

    await openApp(tester);

    expect(find.text(_title), findsNothing);
  });

  testWidgets('does not ask where nothing can record', (tester) async {
    client = FakeAnalyticsClient(isAvailable: false);

    await openApp(tester);

    expect(find.text(_title), findsNothing);
  });
}
