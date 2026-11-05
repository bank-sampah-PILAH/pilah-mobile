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

  static String _screenKey(String userId) => 'analytics_consent_screen:$userId';

  /// [userId]'s choice. When the screen is recorded ([screen]), an agreement
  /// only counts if it was given for that: one given before screens were
  /// recorded promised the opposite, so the user is asked again. A refusal
  /// stays a refusal.
  Future<ConsentChoice> read(String userId, {bool screen = false}) async {
    if (userId.isEmpty) return ConsentChoice.unset;
    final stored = await _storage.get<String>(choiceKey(userId));
    if (stored == 'granted' &&
        screen &&
        await _storage.get<String>(_screenKey(userId)) != 'true') {
      return ConsentChoice.unset;
    }
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

  /// Records an agreement. [screen] says that the user was told the screen is
  /// recorded.
  Future<void> grant(String userId, {bool screen = false}) async {
    await _decide(userId, ConsentChoice.granted);
    if (userId.isNotEmpty && screen) {
      await _storage.put(_screenKey(userId), 'true');
    }
  }

  Future<void> deny(String userId) => _decide(userId, ConsentChoice.denied);

  Future<void> _decide(String userId, ConsentChoice choice) async {
    if (userId.isEmpty) return;
    await _storage.put(choiceKey(userId), choice.name);
    await _storage.put(
        _decidedAtKey(userId), clock.now().toUtc().toIso8601String());
  }
}
