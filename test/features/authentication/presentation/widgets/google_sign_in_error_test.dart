import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/google_sign_in_error.dart';

void main() {
  group('sanitizeGoogleSignInError', () {
    test('a user cancellation returns null (silent abort)', () {
      // This is the exact shape from the bug report:
      // GoogleSignInException(code ...canceled, [16] Cancelled by user., null)
      const error = GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
        description: '[16] Cancelled by user.',
      );
      expect(
        sanitizeGoogleSignInError(error),
        isNull,
        reason: 'cancelling is not a failure — the caller aborts silently',
      );
    });

    test('a legacy sign_in_canceled PlatformException returns null', () {
      expect(
        sanitizeGoogleSignInError(PlatformException(code: 'sign_in_canceled')),
        isNull,
      );
    });

    test('a non-cancel GoogleSignInException degrades to the clean fallback',
        () {
      const error = GoogleSignInException(
        code: GoogleSignInExceptionCode.clientConfigurationError,
        description: 'OAuth client 479665432419 misconfigured',
      );

      final message = sanitizeGoogleSignInError(error);

      expect(message, googleSignInFallbackMessage);
      // The raw technical detail must never reach the UI.
      expect(message, isNot(contains('479665432419')));
      expect(message, isNot(contains('GoogleSignInException')));
    });

    test('interrupted is a real error (fallback), not a silent cancel', () {
      const error =
          GoogleSignInException(code: GoogleSignInExceptionCode.interrupted);
      expect(sanitizeGoogleSignInError(error), googleSignInFallbackMessage);
    });

    test('an arbitrary error never leaks e.toString()', () {
      final message =
          sanitizeGoogleSignInError(Exception('raw socket detail 10.0.2.2'));

      expect(message, googleSignInFallbackMessage);
      expect(message, isNot(contains('raw socket detail')));
      expect(message, isNot(contains('10.0.2.2')));
    });

    test('the fallback message is a clean Indonesian user-facing string', () {
      expect(googleSignInFallbackMessage,
          'Gagal menghubungkan ke akun Google. Silakan coba lagi.');
    });
  });
}
