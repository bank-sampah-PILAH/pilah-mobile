import 'package:clock/clock.dart';
import 'package:pilah_mobile/core/storage/app_storage.dart';

/// What the user decided about being recorded.
enum ConsentChoice { unset, granted, denied }

/// Remembers each user's analytics choice on this device, and when they made
/// it.
///
/// A choice belongs to the person who made it: it is kept under that user's
/// id, so whoever signs in next on the same device is asked for their own. A
/// user without an id has no key to keep a choice under, so nothing is stored.
class AnalyticsConsentStore {
  AnalyticsConsentStore(this._storage);

  /// The storage key holding [userId]'s choice, public so tests can write raw
  /// values.
  static String choiceKey(String userId) => 'analytics_consent_choice:$userId';
  static String _decidedAtKey(String userId) =>
      'analytics_consent_decided_at:$userId';

  final AppStorage _storage;

  Future<ConsentChoice> read(String userId) async {
    if (userId.isEmpty) return ConsentChoice.unset;
    final stored = await _storage.get<String>(choiceKey(userId));
    return switch (stored) {
      'granted' => ConsentChoice.granted,
      'denied' => ConsentChoice.denied,
      _ => ConsentChoice.unset,
    };
  }

  /// When [userId]'s current choice was made, or null if none has been.
  Future<DateTime?> decidedAt(String userId) async {
    if (userId.isEmpty) return null;
    final stored = await _storage.get<String>(_decidedAtKey(userId));
    return stored == null ? null : DateTime.tryParse(stored);
  }

  Future<void> grant(String userId) => _decide(userId, ConsentChoice.granted);

  Future<void> deny(String userId) => _decide(userId, ConsentChoice.denied);

  Future<void> _decide(String userId, ConsentChoice choice) async {
    if (userId.isEmpty) return;
    await _storage.put(choiceKey(userId), choice.name);
    await _storage.put(
        _decidedAtKey(userId), clock.now().toUtc().toIso8601String());
  }
}
