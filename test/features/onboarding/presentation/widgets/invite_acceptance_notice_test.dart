import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/onboarding/presentation/widgets/invite_acceptance_notice.dart';

void main() {
  group('hasRegistrationUnderReview', () {
    test('true while the account waits on its own registration', () {
      // Both signals count: `next_step` is the backend's routing verdict, and
      // `bank_sampah_status` still reads pending in the window where onboarding
      // routes on something else.
      expect(
        hasRegistrationUnderReview(
            step: 'approval_pending', bankSampahStatus: null),
        isTrue,
      );
      expect(
        hasRegistrationUnderReview(
            step: 'complete_profile', bankSampahStatus: 'pending'),
        isTrue,
      );
    });

    test('false for an account that actually runs a bank sampah', () {
      expect(
        hasRegistrationUnderReview(
            step: 'dashboard', bankSampahStatus: 'active'),
        isFalse,
      );
    });

    test('false when there is no registration at all', () {
      expect(
        hasRegistrationUnderReview(step: null, bankSampahStatus: null),
        isFalse,
      );
      expect(
        hasRegistrationUnderReview(
            step: 'register_bank_sampah', bankSampahStatus: null),
        isFalse,
      );
    });

    test('a rejected registration is not under review', () {
      // They can re-apply; telling them a review is in progress would be wrong.
      expect(
        hasRegistrationUnderReview(
            step: 'registration_rejected', bankSampahStatus: 'rejected'),
        isFalse,
      );
    });
  });

  group('joinedMessage', () {
    test('names the bank sampah the invite led to', () {
      expect(
        joinedMessage('BTH Depok'),
        'Berhasil bergabung ke Bank Sampah BTH Depok',
      );
    });

    test('falls back to unnamed copy rather than a dangling label', () {
      // Anything blank would otherwise render "Bank Sampah " with nothing after
      // it — worse than not naming it at all.
      for (final nama in [null, '', '   ']) {
        expect(joinedMessage(nama), 'Berhasil bergabung ke bank sampah');
      }
    });

    test('trims the name it was handed', () {
      expect(
        joinedMessage('  BTH Depok  '),
        'Berhasil bergabung ke Bank Sampah BTH Depok',
      );
    });
  });
}
