import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/analytics/analytics_consent_store.dart';
import 'package:pilah_mobile/core/storage/app_storage.dart';

/// In-memory stand-in for the real key-value storage.
class _FakeStorage implements AppStorage {
  final values = <String, dynamic>{};

  @override
  Future<void> init() async {}

  @override
  Future<void> put(String key, dynamic value) async => values[key] = value;

  @override
  Future<T?> get<T>(String key) async => values[key] as T?;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<void> clear() async => values.clear();

  @override
  Future<bool> contains(String key) async => values.containsKey(key);
}

void main() {
  late _FakeStorage storage;

  setUp(() => storage = _FakeStorage());

  test('no choice has been made until the user decides', () async {
    final store = AnalyticsConsentStore(storage);

    expect(await store.read(), ConsentChoice.unset);
  });

  test('agreeing is remembered', () async {
    final store = AnalyticsConsentStore(storage);

    await store.grant();

    expect(await store.read(), ConsentChoice.granted);
  });

  test('declining is remembered and is not the same as not having chosen',
      () async {
    final store = AnalyticsConsentStore(storage);

    await store.deny();

    expect(await store.read(), ConsentChoice.denied);
  });

  test('the choice survives reopening the app', () async {
    await AnalyticsConsentStore(storage).grant();

    // A new store over the same storage stands for a fresh app start.
    expect(await AnalyticsConsentStore(storage).read(), ConsentChoice.granted);
  });

  test('records when the choice was made', () async {
    final store = AnalyticsConsentStore(storage);
    expect(await store.decidedAt(), isNull);

    await withClock(
      Clock.fixed(DateTime.utc(2026, 11, 2, 10)),
      () => store.grant(),
    );
    expect(await store.decidedAt(), DateTime.utc(2026, 11, 2, 10));

    await withClock(
      Clock.fixed(DateTime.utc(2026, 11, 3, 9)),
      () => store.deny(),
    );
    expect(await store.decidedAt(), DateTime.utc(2026, 11, 3, 9));
  });

  test('a stored value nobody recognises counts as not having chosen',
      () async {
    await storage.put(AnalyticsConsentStore.choiceKey, 'maybe');

    expect(await AnalyticsConsentStore(storage).read(), ConsentChoice.unset);
  });
}
