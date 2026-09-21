import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/router/auth_routing.dart';

void main() {
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

    test('the other onboarding steps are unchanged', () {
      expect(locationForAuthStep('complete_profile'), '/complete-profile');
      expect(
          locationForAuthStep('register_bank_sampah'), '/register-bank-sampah');
      expect(locationForAuthStep('approval_pending'), '/pending-approval');
      expect(
          locationForAuthStep('superadmin_dashboard'), '/superadmin-dashboard');
      expect(locationForAuthStep('register_nasabah'), '/register-nasabah');
      expect(locationForAuthStep('nasabah_dashboard'), '/nasabah-dashboard');
      expect(locationForAuthStep('register_bank_sampah_induk'),
          '/register-bank-sampah-induk');
      expect(locationForAuthStep('pengelola_induk_dashboard'),
          '/pengelola-induk-dashboard');
      expect(locationForAuthStep('dashboard'), '/dashboard');
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

    test('a superadmin is exempt — they belong to no bank sampah', () {
      expect(
        locationForAuthStep(
          'superadmin_dashboard',
          hasPendingInvite: true,
          role: 'superadmin',
        ),
        '/superadmin-dashboard',
      );
    });

    test('an ineligible role keeps its own route while invite is pending', () {
      expect(
        locationForAuthStep(
          'nasabah_dashboard',
          hasPendingInvite: true,
          role: 'nasabah',
        ),
        '/nasabah-dashboard',
      );
    });
  });

  group('pendingInviteLocation', () {
    test('points at the screen that can actually spend the token', () {
      expect(pendingInviteLocation('complete_profile'), '/complete-profile');
      expect(pendingInviteLocation('dashboard'), '/invite-processing');
      expect(pendingInviteLocation('approval_pending'), '/invite-processing');
      expect(pendingInviteLocation(null), '/invite-processing');
    });

    test('is null for a step that can never redeem an invite', () {
      // No route can redeem the token from a superadmin session.
      expect(pendingInviteLocation('superadmin_dashboard'), isNull);
    });
  });
}
