import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/storage/app_storage.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/active_membership_selection.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_approval_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/states/nasabah_approval_state.dart';
import 'package:pilah_mobile/services/di.dart';

/// Where the active bank is kept. Without registered storage this is the
/// do-nothing selection rather than null, so nothing downstream has to ask
/// whether a choice can be kept before trying to keep one.
final activeMembershipSelectionProvider = Provider<ActiveMembershipSelection>(
  (ref) => di.isRegistered<AppStorage>(instanceName: 'shared_preferences')
      ? ActiveMembershipSelection(
          di<AppStorage>(instanceName: 'shared_preferences'))
      : ActiveMembershipSelection.none(),
);

/// Whose choice this is. Empty when nobody is signed in, or the account has
/// no id, because the choice is stored per user.
final activeMembershipUserIdProvider = Provider<String>(
  (ref) {
    final auth = ref.watch(authenticationProvider);
    return auth is Authenticated ? auth.authEntity.id ?? '' : '';
  },
  dependencies: [authenticationProvider],
);

/// The membership the nasabah is currently banking with, or null when they
/// have none they may open. It follows the loaded membership list, so a bank
/// that stops being openable cannot stay active.
final activeMembershipProvider =
    AsyncNotifierProvider<ActiveMembershipNotifier, String?>(
  ActiveMembershipNotifier.new,
  dependencies: [
    activeMembershipSelectionProvider,
    activeMembershipUserIdProvider,
    nasabahApprovalProvider,
  ],
);

class ActiveMembershipNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final selection = ref.watch(activeMembershipSelectionProvider);
    final userId = ref.watch(activeMembershipUserIdProvider);
    // Asked before the membership list is watched: with nowhere to keep a
    // choice there is no reason to make that list load at all, which is what
    // the preview app and the list-only widget tests rely on.
    if (!selection.remembers || userId.isEmpty) return null;
    final approval = ref.watch(nasabahApprovalProvider);
    // Only a loaded list can say which banks are openable. Until then the
    // saved choice is reported as-is, so the screen does not flicker from a
    // marked row to an unmarked one and back on every refresh.
    if (approval is! NasabahApprovalLoaded) return selection.read(userId);
    return selection.resolve(userId, approval.memberships);
  }

  /// Makes [membershipId] the bank the nasabah is banking with, and reports
  /// whether that was saved.
  ///
  /// This never throws. A choice that was not kept leaves the state alone and
  /// returns false, so the bank that is actually active stays on display while
  /// the screen says the choice was not saved, and a failure on a screen the
  /// user has already left cannot surface as an unhandled async error.
  Future<bool> select(String membershipId) async {
    final selection = ref.read(activeMembershipSelectionProvider);
    final userId = ref.read(activeMembershipUserIdProvider);
    if (userId.isEmpty) return false;
    if (!await selection.select(userId, membershipId)) return false;
    // The screen may be gone by now; writing to a disposed notifier throws.
    if (!ref.mounted) return true;
    state = AsyncData(membershipId);
    return true;
  }
}
