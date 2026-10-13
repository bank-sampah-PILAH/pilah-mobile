import 'package:pilah_mobile/core/storage/app_storage.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';

/// Persists one user's active bank membership for the next request layer.
class ActiveMembershipSelection {
  final AppStorage storage;

  const ActiveMembershipSelection(this.storage);

  String _key(String userId) => 'active_membership_id:$userId';

  Future<String?> read(String userId) => storage.get<String>(_key(userId));

  Future<void> select(String userId, String membershipId) =>
      storage.put(_key(userId), membershipId);

  Future<String?> resolve(
    String userId,
    Iterable<NasabahMembershipEntity> memberships,
  ) async {
    final eligible = memberships
        .where(isSelectableMembership)
        .map((membership) => membership.id)
        .toList();
    final saved = await read(userId);
    final selected = eligible.contains(saved) ? saved : eligible.firstOrNull;
    if (selected == null && saved != null) {
      await storage.delete(_key(userId));
    } else if (selected != null && selected != saved) {
      await select(userId, selected);
    }
    return selected;
  }
}

bool isSelectableMembership(NasabahMembershipEntity membership) =>
    membership.status == MembershipStatus.approved && membership.isActive;

BigInt rupiahToCents(String amount) {
  final match = RegExp(r'^(-?)(\d+)(?:\.(\d{1,2}))?$').firstMatch(amount);
  if (match == null) throw FormatException('Invalid decimal balance', amount);
  final fraction = (match.group(3) ?? '').padRight(2, '0');
  final cents = BigInt.parse(match.group(2)!) * BigInt.from(100) +
      BigInt.parse(fraction.isEmpty ? '0' : fraction);
  return match.group(1) == '-' ? -cents : cents;
}

String formatRupiahCents(BigInt cents) {
  final negative = cents.isNegative;
  final absolute = cents.abs();
  final whole = (absolute ~/ BigInt.from(100)).toString();
  final grouped = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return 'Rp ${negative ? '-' : ''}$grouped,${(absolute % BigInt.from(100)).toString().padLeft(2, '0')}';
}

BigInt combinedActiveBalance(Iterable<NasabahMembershipEntity> memberships) =>
    memberships.where(isSelectableMembership).fold(BigInt.zero,
        (total, membership) => total + rupiahToCents(membership.totalSaldo));
