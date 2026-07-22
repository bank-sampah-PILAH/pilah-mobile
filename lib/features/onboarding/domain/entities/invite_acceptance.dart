import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';

/// What `POST /invites/accept` actually said, normalised across the two shapes
/// the backend answers "you are already on a bank sampah" in.
///
/// The endpoint does not report that case one way. The deployed API answers
/// **HTTP 200** with `{"outcome": "already_member", "message": "Anda sudah
/// terdaftar pada bank sampah ini"}` when the account is already on the invite's
/// own bank sampah, while `pilah-be/api/services.py` raises for the neighbouring
/// cases, which the view turns into **HTTP 400** `{"error": …}`. Listening for
/// only one of the two silently drops the other — an uninspected 200 is
/// indistinguishable from a fresh join. Every branch below matches on both.
///
/// Deliberately message-based for the error side: there is no error code in the
/// payload, and no invite-preview endpoint, so the backend's own wording is the
/// only authority on *which* refusal this was.
enum InviteAcceptance {
  /// The account joined the inviting bank sampah.
  joined,

  /// The account is already on this invite's bank sampah — as a member, or as
  /// the primary pengelola who issued the link. Nothing to do, nothing wrong.
  alreadyMember,

  /// The account already belongs to a *different* bank sampah. One account maps
  /// to one bank sampah, so this invite can never be redeemed by it.
  otherBank,

  /// The link itself was refused: invalid, expired, pointing at a bank sampah
  /// that isn't approved, or offered to an account that can't accept invites.
  rejected,

  /// Nothing conclusive came back — offline, timeout, 5xx, or an expired
  /// session. The invite was not spent, so a retry still means something.
  failed;

  /// Whether the backend gave a final answer on this token. Only [failed]
  /// leaves it worth re-submitting.
  bool get isTerminal => this != InviteAcceptance.failed;
}

/// Classifies one `acceptInvite` call from the cubit's `(result, error)` pair.
InviteAcceptance classifyInviteAcceptance({
  required OnboardingResult? result,
  required NetworkException? error,
}) {
  if (error == null) {
    return (result?.isAlreadyMember ?? false)
        ? InviteAcceptance.alreadyMember
        : InviteAcceptance.joined;
  }

  final reason = error.displayMessage.toLowerCase();

  // "Pengelola utama tidak dapat menerima tautan undangan miliknya sendiri" —
  // the owner of the very bank sampah this link belongs to. Same situation as
  // the 200 `already_member`, phrased as a rejection.
  if (reason.contains('utama') || reason.contains('sudah terdaftar')) {
    return InviteAcceptance.alreadyMember;
  }
  // "Akun ini sudah tergabung dengan bank sampah".
  if (reason.contains('sudah tergabung') ||
      reason.contains('sudah bergabung') ||
      reason.contains('sudah menjadi')) {
    return InviteAcceptance.otherBank;
  }
  // "Tautan undangan tidak valid atau sudah kedaluwarsa", or a role this flow
  // doesn't accept ("Hanya pengelola yang dapat menerima undangan").
  if (reason.contains('tidak valid') ||
      reason.contains('kedaluwarsa') ||
      reason.contains('undangan')) {
    return InviteAcceptance.rejected;
  }
  // Transport and auth failures carry no verdict about the invite itself.
  return InviteAcceptance.failed;
}
