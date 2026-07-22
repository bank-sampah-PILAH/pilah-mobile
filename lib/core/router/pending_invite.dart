import 'package:pilah_mobile/core/router/auth_routing.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/services/di.dart';

/// Where a banked invite token should take a signed-in user, discarding the
/// token when this session can never spend it.
///
/// The discarding is the point. A token now survives logout (see
/// `resetSessionScopedState`), so one tapped during a session with no way to
/// redeem it would sit in the store and follow the *next* account signed in on
/// this device into a bank sampah nobody invited them to. A superadmin session
/// is exactly that: they belong to no bank sampah, and `POST /invites/accept`
/// refuses them outright behind `IsPengelola`. Dropping the token on the first
/// routing pass of their session is the narrowest place to catch it.
///
/// Returns `null` when there is nothing to redeem, or nothing here that can
/// redeem it.
String? resolvePendingInvite({required String? step, required String? role}) {
  final store = di<InviteTokenStore>();
  if (!store.hasToken) return null;

  // Role is checked ahead of the step: it is the backend's own answer, and it
  // stays correct even if a superadmin's `next_step` is ever something other
  // than their dashboard.
  final target = role == 'superadmin' ? null : pendingInviteLocation(step);
  if (target == null) {
    store.clear();
    return null;
  }
  return target;
}
