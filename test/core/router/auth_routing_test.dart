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
      expect(locationForAuthStep('register_bank_sampah'), '/register-bank-sampah');
      expect(locationForAuthStep('approval_pending'), '/pending-approval');
      expect(locationForAuthStep('superadmin_dashboard'), '/superadmin-dashboard');
      expect(locationForAuthStep('dashboard'), '/dashboard');
      expect(locationForAuthStep(null), '/dashboard');
    });

    test('a pending invite still outranks a rejected registration', () {
      expect(
        locationForAuthStep('registration_rejected', hasPendingInvite: true),
        '/complete-profile',
      );
    });
  });
}
