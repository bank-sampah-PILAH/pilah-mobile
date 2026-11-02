import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/analytics/analytics_consent_store.dart';
import 'package:pilah_mobile/design/theme/app_theme.dart';
import 'package:pilah_mobile/features/analytics/presentation/providers/analytics_consent_provider.dart';
import 'package:pilah_mobile/features/analytics/presentation/widgets/analytics_consent_card.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/fake_analytics_client.dart';
import '../../../../support/fake_app_storage.dart';

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

  Future<void> openCard(WidgetTester tester) async {
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
        home: const Scaffold(body: AnalyticsConsentCard()),
      ),
    ));
    await tester.pumpAndSettle();
  }

  bool switchValue(WidgetTester tester) =>
      tester.widget<Switch>(find.byType(Switch)).value;

  testWidgets('shows the current choice: on after agreeing', (tester) async {
    await AnalyticsConsentStore(storage).grant();

    await openCard(tester);

    expect(find.text('Perekaman sesi'), findsOneWidget);
    expect(switchValue(tester), isTrue);
  });

  testWidgets('shows off when the pengurus has not agreed or has declined',
      (tester) async {
    await openCard(tester);
    expect(switchValue(tester), isFalse);

    await AnalyticsConsentStore(storage).deny();
    await openCard(tester);
    expect(switchValue(tester), isFalse);
  });

  testWidgets('switching it on agrees and starts recording', (tester) async {
    await openCard(tester);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(client.calls, ['start']);
    expect(await AnalyticsConsentStore(storage).read(), ConsentChoice.granted);
    expect(switchValue(tester), isTrue);
  });

  testWidgets('switching it off withdraws consent and stops recording',
      (tester) async {
    await AnalyticsConsentStore(storage).grant();
    await openCard(tester);
    client.calls.clear();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(client.calls, ['stop']);
    expect(await AnalyticsConsentStore(storage).read(), ConsentChoice.denied);
    expect(switchValue(tester), isFalse);
  });

  testWidgets('is not shown to a nasabah', (tester) async {
    role = 'nasabah';

    await openCard(tester);

    expect(find.byType(Switch), findsNothing);
    expect(find.text('Perekaman sesi'), findsNothing);
  });

  testWidgets('is not shown where nothing can record', (tester) async {
    client = FakeAnalyticsClient(isAvailable: false);

    await openCard(tester);

    expect(find.byType(Switch), findsNothing);
  });
}
