import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:pilah_mobile/core/analytics/analytics_consent_store.dart';
import 'package:pilah_mobile/features/analytics/presentation/providers/analytics_consent_provider.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/fake_app_storage.dart';

/// Records what it was asked to do, in order.
class _FakeClient implements AnalyticsClient {
  _FakeClient({this.isAvailable = true});

  @override
  final bool isAvailable;
  final calls = <String>[];

  @override
  Future<void> start() async => calls.add('start');

  @override
  Future<void> stop() async => calls.add('stop');
}

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
  late _FakeClient client;
  late TestAuthenticationNotifier auth;

  setUp(() {
    storage = FakeAppStorage();
    client = _FakeClient();
    auth = TestAuthenticationNotifier(initialState: _signedInAs('pengelola'));
  });

  ProviderContainer containerForTest() {
    final container = ProviderContainer(overrides: [
      authenticationProvider.overrideWith(() => auth),
      analyticsClientProvider.overrideWithValue(client),
      analyticsConsentStoreProvider
          .overrideWithValue(AnalyticsConsentStore(storage)),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('nothing starts until the pengurus has chosen', () async {
    final container = containerForTest();

    final choice = await container.read(analyticsConsentProvider.future);

    expect(choice, ConsentChoice.unset);
    expect(client.calls, isEmpty);
  });

  test('a pengurus who agreed before is recorded again without being asked',
      () async {
    await AnalyticsConsentStore(storage).grant();
    final container = containerForTest();

    final choice = await container.read(analyticsConsentProvider.future);

    expect(choice, ConsentChoice.granted);
    expect(client.calls, ['start']);
  });

  test('a nasabah is never recorded, even if the device remembers an agreement',
      () async {
    await AnalyticsConsentStore(storage).grant();
    auth.setStateForTest(_signedInAs('nasabah'));
    final container = containerForTest();

    await container.read(analyticsConsentProvider.future);

    expect(client.calls, isNot(contains('start')));
  });

  test(
      'recording stops when the pengurus signs out and someone else takes over',
      () async {
    await AnalyticsConsentStore(storage).grant();
    final container = containerForTest();
    await container.read(analyticsConsentProvider.future);
    expect(client.calls, ['start']);

    auth.setStateForTest(_signedInAs('nasabah'));
    await container.read(analyticsConsentProvider.future);

    expect(client.calls, ['start', 'stop']);
  });

  test('agreeing remembers the choice and starts recording', () async {
    final container = containerForTest();
    await container.read(analyticsConsentProvider.future);

    await container.read(analyticsConsentProvider.notifier).grant();

    expect(client.calls, ['start']);
    expect(await AnalyticsConsentStore(storage).read(), ConsentChoice.granted);
    expect(
        container.read(analyticsConsentProvider).value, ConsentChoice.granted);
  });

  group('asking for consent', () {
    Future<bool> needsPrompt(ProviderContainer container) async {
      await container.read(analyticsConsentProvider.future);
      return container.read(analyticsNeedsPromptProvider);
    }

    test('a pengurus who has not chosen is asked', () async {
      expect(await needsPrompt(containerForTest()), isTrue);
    });

    test('a nasabah is never asked', () async {
      auth.setStateForTest(_signedInAs('nasabah'));

      expect(await needsPrompt(containerForTest()), isFalse);
    });

    test('nobody is asked about a recorder that cannot record', () async {
      client = _FakeClient(isAvailable: false);

      expect(await needsPrompt(containerForTest()), isFalse);
    });

    test('nobody is asked twice, whatever they answered', () async {
      for (final answer in [
        (AnalyticsConsentStore store) => store.grant(),
        (AnalyticsConsentStore store) => store.deny(),
      ]) {
        // A fresh app start each time: new storage, session and notifier.
        storage = FakeAppStorage();
        auth =
            TestAuthenticationNotifier(initialState: _signedInAs('pengelola'));
        await answer(AnalyticsConsentStore(storage));

        expect(await needsPrompt(containerForTest()), isFalse);
      }
    });
  });

  test('declining remembers the choice and never starts recording', () async {
    final container = containerForTest();
    await container.read(analyticsConsentProvider.future);

    await container.read(analyticsConsentProvider.notifier).deny();

    expect(client.calls, isEmpty);
    expect(await AnalyticsConsentStore(storage).read(), ConsentChoice.denied);
    expect(
        container.read(analyticsConsentProvider).value, ConsentChoice.denied);
  });

  test('withdrawing consent stops recording and remembers the refusal',
      () async {
    final container = containerForTest();
    await container.read(analyticsConsentProvider.future);
    await container.read(analyticsConsentProvider.notifier).grant();

    await container.read(analyticsConsentProvider.notifier).revoke();

    expect(client.calls, ['start', 'stop']);
    expect(await AnalyticsConsentStore(storage).read(), ConsentChoice.denied);
    expect(
        container.read(analyticsConsentProvider).value, ConsentChoice.denied);
  });
}
