import 'package:pilah_mobile/core/router/auth_routing.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/services/di.dart';

/// Where a banked invite token should take a signed-in user, discarding the
/// token when this session can never spend it.
///
/// The discarding is the point. A token now survives logout (see
/// `resetSessionScopedState`), so one tapped during a session with no way to
/// redeem it would sit in the store and follow the *next* account signed in on
/// this device into a bank sampah nobody invited them to. Superadmin and
/// Pengelola Induk roles cannot redeem invites because `POST /invites/accept`
/// refuses them behind `IsPengelola`. A missing role can be a partial auth
/// response, so keep the token until the account is known.
///
/// Returns `null` when there is nothing to redeem, or nothing here that can
/// redeem it.
String? resolvePendingInvite({required String? step, required String? role}) {
  final store = di<InviteTokenStore>();
  if (!store.hasToken) return null;

  // The backend explicitly refuses these roles. Keep a token when the role is
  // absent from a partial auth response so it can still be redeemed later.
  final target = role == 'superadmin' || role == 'pengelola_induk'
      ? null
      : pendingInviteLocation(step);
  if (target == null) {
    store.clear();
    return null;
  }
  return target;
}
