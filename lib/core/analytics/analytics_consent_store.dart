import 'package:clock/clock.dart';
import 'package:pilah_mobile/core/storage/app_storage.dart';

/// What the user decided about being recorded.
enum ConsentChoice { unset, granted, denied }

/// Remembers the user's recording choice on this device, and when they made it.
class AnalyticsConsentStore {
  AnalyticsConsentStore(this._storage);

  /// The storage key holding the choice, public so tests can write raw values.
  static const choiceKey = 'analytics_consent_choice';
  static const _decidedAtKey = 'analytics_consent_decided_at';

  final AppStorage _storage;

  Future<ConsentChoice> read() async {
    final stored = await _storage.get<String>(choiceKey);
    return switch (stored) {
      'granted' => ConsentChoice.granted,
      'denied' => ConsentChoice.denied,
      _ => ConsentChoice.unset,
    };
  }

  /// When the current choice was made, or null if none has been.
  Future<DateTime?> decidedAt() async {
    final stored = await _storage.get<String>(_decidedAtKey);
    return stored == null ? null : DateTime.tryParse(stored);
  }

  Future<void> grant() => _decide(ConsentChoice.granted);

  Future<void> deny() => _decide(ConsentChoice.denied);

  Future<void> _decide(ConsentChoice choice) async {
    await _storage.put(choiceKey, choice.name);
    await _storage.put(_decidedAtKey, clock.now().toUtc().toIso8601String());
  }
}
