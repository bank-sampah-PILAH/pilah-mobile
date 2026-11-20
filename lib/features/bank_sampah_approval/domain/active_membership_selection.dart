import 'dart:async';

import 'package:pilah_mobile/core/storage/app_storage.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';

/// One user's active bank membership.
///
/// Null Object: callers never hold a null selection. Where no storage was
/// registered, as in previews and in widget tests that only care about the
/// list, [ActiveMembershipSelection.none] stands in and remembers nothing, so
/// the screens ask it the same questions and get the same shape of answer
/// instead of guarding every call site.
abstract class ActiveMembershipSelection {
  const ActiveMembershipSelection._();

  /// Keeps the choice in [storage], where it survives a restart.
  const factory ActiveMembershipSelection(AppStorage storage) =
      _StoredActiveMembershipSelection;

  /// Remembers nothing: no bank is ever active and no choice is ever kept.
  const factory ActiveMembershipSelection.none() = _NoActiveMembershipSelection;

  /// Whether a choice can be kept at all. Callers use it to skip work that
  /// only pays off when something can be remembered, such as loading the
  /// membership list purely to reconcile a saved choice against it.
  bool get remembers;

  /// The membership saved for [userId], or null when there is none.
  Future<String?> read(String userId);

  /// Remembers [membershipId] for [userId], answering whether it was kept.
  /// False means the choice did not survive, so nothing should claim it did.
  Future<bool> select(String userId, String membershipId);

  /// The membership [userId] should be banking with out of [memberships]:
  /// their saved choice while it can still be opened, otherwise the first one
  /// that can, and null when none can.
  Future<String?> resolve(
    String userId,
    Iterable<NasabahMembershipEntity> memberships,
  );
}

/// Persists one user's active bank membership for the next request layer.
class _StoredActiveMembershipSelection extends ActiveMembershipSelection {
  static final _queues = <String, Future<void>>{};

  final AppStorage storage;

  const _StoredActiveMembershipSelection(this.storage) : super._();

  @override
  bool get remembers => true;

  String _key(String userId) => 'active_membership_id:$userId';

  Future<T> _serialize<T>(String userId, Future<T> Function() operation) {
    final queued =
        (_queues[userId] ?? Future<void>.value()).then((_) => operation());
    final tail = queued.then<void>((_) {}, onError: (Object _) {});
    _queues[userId] = tail;
    tail.whenComplete(() {
      if (identical(_queues[userId], tail)) _queues.remove(userId);
    });
    return queued;
  }

  @override
  Future<String?> read(String userId) =>
      _serialize(userId, () => storage.get<String>(_key(userId)));

  @override
  Future<bool> select(String userId, String membershipId) async {
    // The object that owns the storage owns its failure mode, so callers get
    // an answer rather than an exception to interpret.
    try {
      await _serialize(userId, () => storage.put(_key(userId), membershipId));
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> resolve(
    String userId,
    Iterable<NasabahMembershipEntity> memberships,
  ) =>
      _serialize(userId, () => _resolve(userId, memberships));

  Future<String?> _resolve(
    String userId,
    Iterable<NasabahMembershipEntity> memberships,
  ) async {
    final key = _key(userId);
    final eligible = memberships
        .where(isSelectableMembership)
        .map((membership) => membership.id)
        .toList();
    final saved = await storage.get<String>(key);
    final selected = eligible.contains(saved) ? saved : eligible.firstOrNull;
    if (selected == null && saved != null) {
      await storage.delete(key);
    } else if (selected != null && selected != saved) {
      await storage.put(key, selected);
    }
    return selected;
  }
}

/// The do-nothing selection. Every answer is "nothing is remembered", which
/// is exactly what the screens should show when there is nowhere to remember.
class _NoActiveMembershipSelection extends ActiveMembershipSelection {
  const _NoActiveMembershipSelection() : super._();

  @override
  bool get remembers => false;

  @override
  Future<String?> read(String userId) async => null;

  @override
  Future<bool> select(String userId, String membershipId) async => false;

  @override
  Future<String?> resolve(
    String userId,
    Iterable<NasabahMembershipEntity> memberships,
  ) async =>
      null;
}

/// Whether a membership can be made the active one. This defers to the
/// backend's [NasabahMembershipEntity.dapatDibuka] rather than re-deriving it
/// from status and isActive, because those two cannot see a deactivated bank
/// and would offer a membership the API answers 403 for.
bool isSelectableMembership(NasabahMembershipEntity membership) =>
    membership.dapatDibuka;
