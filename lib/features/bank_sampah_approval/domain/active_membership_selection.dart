import 'dart:async';

import 'package:pilah_mobile/core/storage/app_storage.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';

/// Persists one user's active bank membership for the next request layer.
class ActiveMembershipSelection {
  static final _queues = <String, Future<void>>{};

  final AppStorage storage;

  const ActiveMembershipSelection(this.storage);

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

  Future<String?> read(String userId) =>
      _serialize(userId, () => storage.get<String>(_key(userId)));

  Future<void> select(String userId, String membershipId) =>
      _serialize(userId, () => storage.put(_key(userId), membershipId));

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

/// Whether a membership can be made the active one. This defers to the
/// backend's [NasabahMembershipEntity.dapatDibuka] rather than re-deriving it
/// from status and isActive, because those two cannot see a deactivated bank
/// and would offer a membership the API answers 403 for.
bool isSelectableMembership(NasabahMembershipEntity membership) =>
    membership.dapatDibuka;
