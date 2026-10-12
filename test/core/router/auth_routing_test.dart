import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/router/auth_routing.dart';

void main() {
  group('isSupportedWebRole', () {
    test('allows only roles supported by the web app', () {
      for (final role in ['superadmin', 'pengelola', 'pengelola_induk']) {
        expect(isSupportedWebRole(role), isTrue);
      }
      for (final role in ['nasabah', 'unknown', null]) {
        expect(isSupportedWebRole(role), isFalse);
      }
    });
  });

  group('isRoleSupportedOnPlatform', () {
    test('filters unsupported web roles only on web', () {
      expect(isRoleSupportedOnPlatform('pengelola', isWeb: true), isTrue);
      expect(isRoleSupportedOnPlatform('nasabah', isWeb: true), isFalse);
      expect(isRoleSupportedOnPlatform('nasabah', isWeb: false), isTrue);
    });
  });

  group('webRoleRedirect', () {
    test('redirects unsupported roles but leaves supported roles and login',
        () {
      expect(
        webRoleRedirect(
          isWeb: true,
          path: '/dashboard',
          loginPath: '/login',
          role: 'nasabah',
        ),
        '/login',
      );
      expect(
        webRoleRedirect(
          isWeb: true,
          path: '/dashboard',
          loginPath: '/login',
          role: 'pengelola',
        ),
        isNull,
      );
      expect(
        webRoleRedirect(
          isWeb: true,
          path: '/login',
          loginPath: '/login',
          role: 'nasabah',
        ),
        isNull,
      );
      expect(
        webRoleRedirect(
          isWeb: false,
          path: '/dashboard',
          loginPath: '/login',
          role: 'nasabah',
        ),
        isNull,
      );
    });
  });

  group('locationForAuthStep', () {
    test('a rejected registration routes to the registration form (re-apply)',
        () {
      expect(
        locationForAuthStep('registration_rejected'),
        '/register-bank-sampah',
        reason: 'a rejected user must be able to re-apply, not be stranded on '
            'the pending screen',
      );
    });

    test('routes backend steps for all four roles', () {
      // Pengurus is `pengelola` in the backend role enum.
      expect(
        locationForAuthStep('complete_profile', role: 'pengelola'),
        '/complete-profile',
      );
      expect(
        locationForAuthStep('register_bank_sampah', role: 'pengelola'),
        '/register-bank-sampah',
      );
      expect(
        locationForAuthStep('approval_pending', role: 'pengelola'),
        '/pending-approval',
      );
      expect(
        locationForAuthStep('dashboard', role: 'pengelola'),
        '/dashboard',
      );
      expect(
        locationForAuthStep('superadmin_dashboard', role: 'superadmin'),
        '/superadmin-dashboard',
      );
      expect(
        locationForAuthStep('register_nasabah', role: 'nasabah'),
        '/register-nasabah',
      );
      expect(
        locationForAuthStep('nasabah_dashboard', role: 'nasabah'),
        '/dashboard',
      );
      expect(
        locationForAuthStep('register_bank_sampah_induk',
            role: 'pengelola_induk'),
        '/register-bank-sampah-induk',
      );
      expect(
        locationForAuthStep('pengelola_induk_dashboard',
            role: 'pengelola_induk'),
        '/pengelola-induk-dashboard',
      );
      expect(locationForAuthStep(null), '/dashboard');
    });

    test('an incomplete profile redeems the invite on the completion form', () {
      expect(
        locationForAuthStep(
          'complete_profile',
          hasPendingInvite: true,
          role: 'pengelola',
        ),
        '/complete-profile',
      );
    });

    test('a pending invite outranks every other onboarding step', () {
      // A complete profile can't use the completion form (it would be trapped
      // on "Profil sudah lengkap"), so every one of these hands off to the gate.
      for (final step in [
        'registration_rejected',
        'register_bank_sampah',
        'approval_pending',
        'dashboard',
        null
      ]) {
        expect(
          locationForAuthStep(
            step,
            hasPendingInvite: true,
            role: 'pengelola',
          ),
          '/invite-processing',
          reason: 'step "$step" must not swallow a pending invite',
        );
      }
    });

    test('an already-signed-in user on the dashboard is pulled into the gate',
        () {
      // The warm-start case: tapping an invite link while sitting on the
      // dashboard used to leave the user there, so /invites/accept was never
      // called.
      expect(
        locationForAuthStep(
          'dashboard',
          hasPendingInvite: true,
          role: 'pengelola',
        ),
        '/invite-processing',
      );
    });

    test('non-pengelola roles do not enter the invite flow', () {
      expect(
        locationForAuthStep(
          'superadmin_dashboard',
          hasPendingInvite: true,
          role: 'superadmin',
        ),
        '/superadmin-dashboard',
      );
      expect(
        locationForAuthStep(
          'pengelola_induk_dashboard',
          hasPendingInvite: true,
          role: 'pengelola_induk',
        ),
        '/pengelola-induk-dashboard',
      );
    });

    test('an ineligible role keeps its own route while invite is pending', () {
      expect(
        locationForAuthStep(
          'nasabah_dashboard',
          hasPendingInvite: true,
          role: 'nasabah',
        ),
        '/dashboard',
      );
    });

    test('a missing role does not enter the invite flow', () {
      expect(
        locationForAuthStep('dashboard', hasPendingInvite: true),
        '/dashboard',
      );
    });
  });

  group('pendingInviteLocation', () {
    test('points at the screen that can actually spend the token', () {
      expect(
        pendingInviteLocation('complete_profile', role: 'pengelola'),
        '/complete-profile',
      );
      expect(
        pendingInviteLocation('dashboard', role: 'pengelola'),
        '/invite-processing',
      );
      expect(
        pendingInviteLocation('approval_pending', role: 'pengelola'),
        '/invite-processing',
      );
      expect(
        pendingInviteLocation(null, role: 'pengelola'),
        '/invite-processing',
      );
    });

    test('is null for a step that can never redeem an invite', () {
      // No route can redeem the token from a superadmin session.
      expect(
        pendingInviteLocation('superadmin_dashboard', role: 'superadmin'),
        isNull,
      );
      expect(
        pendingInviteLocation('nasabah_dashboard', role: 'nasabah'),
        isNull,
      );
      expect(pendingInviteLocation('dashboard', role: null), isNull);
    });
  });

  group('sessionRestoreRedirect', () {
    test('sends a protected path to the splash until the session is checked',
        () {
      for (final path in ['/dashboard', '/nasabah', '/profile', '/laporan']) {
        expect(
          sessionRestoreRedirect(sessionChecked: false, path: path),
          '/splash?from=${Uri.encodeComponent(path)}',
          reason: path,
        );
      }
    });

    test('carries the query string so the page keeps its state', () {
      expect(
        sessionRestoreRedirect(
          sessionChecked: false,
          path: '/jadwal',
          query: 'date=2026-10-20',
        ),
        '/splash?from=${Uri.encodeComponent('/jadwal?date=2026-10-20')}',
      );
    });

    test('leaves public paths alone so the splash can finish its work', () {
      for (final path in [
        '/splash',
        '/login',
        '/choose-role',
        '/forgot_password',
        '/invite',
      ]) {
        expect(
          sessionRestoreRedirect(sessionChecked: false, path: path),
          isNull,
          reason: path,
        );
      }
    });

    test('does nothing once the session has been checked', () {
      expect(
        sessionRestoreRedirect(sessionChecked: true, path: '/dashboard'),
        isNull,
      );
    });
  });

  group('locationAfterRestore', () {
    test('returns to the page the user refreshed on', () {
      expect(
        locationAfterRestore(target: '/dashboard', from: '/nasabah'),
        '/nasabah',
      );
    });

    test('returns Super Admin and Pengurus Induk to the page they were on', () {
      for (final home in [
        '/superadmin-dashboard',
        '/pengelola-induk-dashboard',
      ]) {
        expect(
          locationAfterRestore(target: home, from: '/profile'),
          '/profile',
          reason: home,
        );
      }
    });

    test('keeps the onboarding step when the user is not onboarded', () {
      expect(
        locationAfterRestore(target: '/pending-approval', from: '/nasabah'),
        '/pending-approval',
      );
    });

    test('restores the query string along with the path', () {
      expect(
        locationAfterRestore(
          target: '/dashboard',
          from: '/jadwal?date=2026-10-20',
        ),
        '/jadwal?date=2026-10-20',
      );
    });

    test('ignores a missing or unsafe from', () {
      for (final from in [
        null,
        '',
        'nasabah',
        '//evil.test',
        '/login',
        '/login?next=/nasabah',
      ]) {
        expect(
          locationAfterRestore(target: '/dashboard', from: from),
          '/dashboard',
          reason: '$from',
        );
      }
    });
  });

  group('signedOutRedirect', () {
    test('sends a protected path to login once the user is signed out', () {
      for (final path in ['/dashboard', '/nasabah', '/profile']) {
        expect(signedOutRedirect(signedOut: true, path: path), '/login',
            reason: path);
      }
    });

    test('leaves public paths alone', () {
      for (final path in ['/splash', '/login', '/choose-role']) {
        expect(signedOutRedirect(signedOut: true, path: path), isNull,
            reason: path);
      }
    });

    test('does nothing while a session exists', () {
      expect(signedOutRedirect(signedOut: false, path: '/dashboard'), isNull);
    });
  });
}
