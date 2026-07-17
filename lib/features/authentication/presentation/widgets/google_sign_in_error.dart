import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart';

/// User-facing fallback for a Google sign-in failure that is not a deliberate
/// cancellation. Generic on purpose — a raw exception string is never shown to
/// the user.
const googleSignInFallbackMessage =
    'Gagal menghubungkan ke akun Google. Silakan coba lagi.';

/// Translates a raw Google sign-in [error] into a user-facing message, or
/// `null` when the user intentionally cancelled or dismissed the account
/// picker — in which case the caller should silently abort with no error UI
/// (cancelling is not a failure to scold the user for).
///
/// Never returns `error.toString()`: every unrecognised failure degrades to
/// [googleSignInFallbackMessage], so technical text (OAuth client ids, status
/// codes, stack details) can never leak into the UI.
String? sanitizeGoogleSignInError(Object error) {
  // google_sign_in v7 surfaces a cancel/dismiss as GoogleSignInException with
  // code `canceled` (the "[16] Cancelled by user." case in the wild).
  if (error is GoogleSignInException &&
      error.code == GoogleSignInExceptionCode.canceled) {
    return null;
  }
  // Legacy platform-channel cancellation codes, in case an older code path or
  // plugin surfaces one instead of a GoogleSignInException.
  if (error is PlatformException &&
      (error.code == 'sign_in_canceled' || error.code == 'canceled')) {
    return null;
  }
  return googleSignInFallbackMessage;
}
