import 'package:pilah_mobile/core/router/auth_routing.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/services/di.dart';

/// Where a banked invite token should take a signed-in user, discarding the
/// token when this session can never spend it.
///
/// The discarding is the point. A token now survives logout (see
/// `resetSessionScopedState`), so one tapped during a session with no way to
/// redeem it would sit in the store and follow the *next* account signed in on
/// this device into a bank sampah nobody invited them to. Only Pengurus
/// (`pengelola`) can redeem invites; Nasabah, Superadmin, and Pengelola Induk
/// are refused by `POST /invites/accept`. A missing or unknown role may be a
/// partial auth response, so keep the token until the account is known.
///
/// Returns `null` when there is nothing to redeem, or nothing here that can
/// redeem it.
String? resolvePendingInvite({required String? step, required String? role}) {
  final store = di<InviteTokenStore>();
  if (!store.hasToken) return null;

  if (role == 'pengelola') {
    final target = pendingInviteLocation(step, role: role);
    if (target == null) {
      store.clear();
      return null;
    }
    return target;
  }

  // Only discard for roles the backend is known to reject. A missing or
  // unrecognized role may be a partial auth response, so don't lose the token.
  if (role == 'nasabah' || role == 'superadmin' || role == 'pengelola_induk') {
    store.clear();
  }
  return null;
}
