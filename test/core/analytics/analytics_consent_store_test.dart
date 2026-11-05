import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/analytics/analytics_consent_store.dart';
import '../../support/fake_app_storage.dart';

void main() {
  late FakeAppStorage storage;

  setUp(() => storage = FakeAppStorage());

  test('no choice has been made until the user decides', () async {
    final store = AnalyticsConsentStore(storage);

    expect(await store.read('u1'), ConsentChoice.unset);
  });

  test('agreeing is remembered', () async {
    final store = AnalyticsConsentStore(storage);

    await store.grant('u1');

    expect(await store.read('u1'), ConsentChoice.granted);
  });

  test('declining is remembered and is not the same as not having chosen',
      () async {
    final store = AnalyticsConsentStore(storage);

    await store.deny('u1');

    expect(await store.read('u1'), ConsentChoice.denied);
  });

  group('when the screen is recorded', () {
    test('an agreement given before screens were recorded is asked again',
        () async {
      final store = AnalyticsConsentStore(storage);
      await store.grant('u1');

      expect(await store.read('u1', screen: true), ConsentChoice.unset);
      // Where the screen is not recorded, nothing changes.
      expect(await store.read('u1'), ConsentChoice.granted);
    });

    test('an agreement given for it holds, and survives reopening', () async {
      await AnalyticsConsentStore(storage).grant('u1', screen: true);

      expect(
        await AnalyticsConsentStore(storage).read('u1', screen: true),
        ConsentChoice.granted,
      );
    });

    test('a refusal stays a refusal', () async {
      final store = AnalyticsConsentStore(storage);
      await store.deny('u1');

      expect(await store.read('u1', screen: true), ConsentChoice.denied);
    });

    test('the agreement is per user', () async {
      final store = AnalyticsConsentStore(storage);
      await store.grant('u1', screen: true);
      await store.grant('u2');

      expect(await store.read('u2', screen: true), ConsentChoice.unset);
    });

    test('nobody without an id has an agreement to keep', () async {
      final store = AnalyticsConsentStore(storage);
      await store.grant('', screen: true);

      expect(await store.read('', screen: true), ConsentChoice.unset);
    });
  });

  test('the choice survives reopening the app', () async {
    await AnalyticsConsentStore(storage).grant('u1');

    // A new store over the same storage stands for a fresh app start.
    expect(
        await AnalyticsConsentStore(storage).read('u1'), ConsentChoice.granted);
  });

  test('a choice belongs to the user who made it, not to the device', () async {
    final store = AnalyticsConsentStore(storage);

    await store.grant('u1');

    expect(await store.read('u2'), ConsentChoice.unset);
    expect(await store.decidedAt('u2'), isNull);
  });

  test('every user keeps their own choice', () async {
    final store = AnalyticsConsentStore(storage);

    await store.grant('u1');
    await store.deny('u2');

    expect(await store.read('u1'), ConsentChoice.granted);
    expect(await store.read('u2'), ConsentChoice.denied);
  });

  test('a choice made before choices were kept per user is not carried over',
      () async {
    await storage.put('analytics_consent_choice', 'granted');

    expect(
        await AnalyticsConsentStore(storage).read('u1'), ConsentChoice.unset);
  });

  test('without a user there is nothing to remember', () async {
    final store = AnalyticsConsentStore(storage);

    await store.grant('');

    expect(await store.read(''), ConsentChoice.unset);
    expect(
        await storage.get<String>(AnalyticsConsentStore.choiceKey('')), isNull);
  });

  test('records when the choice was made', () async {
    final store = AnalyticsConsentStore(storage);
    expect(await store.decidedAt('u1'), isNull);

    await withClock(
      Clock.fixed(DateTime.utc(2026, 11, 2, 10)),
      () => store.grant('u1'),
    );
    expect(await store.decidedAt('u1'), DateTime.utc(2026, 11, 2, 10));

    await withClock(
      Clock.fixed(DateTime.utc(2026, 11, 3, 9)),
      () => store.deny('u1'),
    );
    expect(await store.decidedAt('u1'), DateTime.utc(2026, 11, 3, 9));
  });

  test('a stored value nobody recognises counts as not having chosen',
      () async {
    await storage.put(AnalyticsConsentStore.choiceKey('u1'), 'maybe');

    expect(
        await AnalyticsConsentStore(storage).read('u1'), ConsentChoice.unset);
  });
}
