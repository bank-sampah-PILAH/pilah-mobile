import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/invite_acceptance.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';

NetworkException _badRequest(String error) =>
    NetworkException.handleBadResponse(
      Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/invites/accept'),
        statusCode: 400,
        data: {'error': error},
      ),
    );

void main() {
  group('OnboardingResult.isAlreadyMember', () {
    test('reads the outcome the deployed API returns with HTTP 200', () {
      // The bug this guards: the backend does not reject an account that is
      // already on this bank sampah, it answers 200. Keeping only `next_step`
      // made that indistinguishable from a fresh join.
      const result = OnboardingResult(
        nextStep: 'dashboard',
        outcome: 'already_member',
        message: 'Anda sudah terdaftar pada bank sampah ini',
      );
      expect(result.isAlreadyMember, isTrue);
    });

    test('falls back to the message when no outcome field is present', () {
      const result = OnboardingResult(
        nextStep: 'dashboard',
        message: 'Anda sudah terdaftar pada bank sampah ini',
      );
      expect(result.isAlreadyMember, isTrue);
    });

    test('a plain join is not mistaken for an existing membership', () {
      expect(const OnboardingResult(nextStep: 'dashboard').isAlreadyMember,
          isFalse);
      expect(
        const OnboardingResult(nextStep: 'dashboard', outcome: 'joined')
            .isAlreadyMember,
        isFalse,
      );
    });
  });

  group('classifyInviteAcceptance', () {
    test('HTTP 200 with outcome already_member is not a join', () {
      expect(
        classifyInviteAcceptance(
          result: const OnboardingResult(
            nextStep: 'dashboard',
            outcome: 'already_member',
            message: 'Anda sudah terdaftar pada bank sampah ini',
          ),
          error: null,
        ),
        InviteAcceptance.alreadyMember,
      );
    });

    test('HTTP 200 without that outcome is a join', () {
      expect(
        classifyInviteAcceptance(
          result: const OnboardingResult(nextStep: 'dashboard'),
          error: null,
        ),
        InviteAcceptance.joined,
      );
    });

    test('the primary pengelola of this bank sampah reads as already a member',
        () {
      expect(
        classifyInviteAcceptance(
          result: null,
          error: _badRequest(
              'Pengelola utama tidak dapat menerima tautan undangan miliknya sendiri'),
        ),
        InviteAcceptance.alreadyMember,
      );
    });

    test('an account on a different bank sampah is its own outcome', () {
      expect(
        classifyInviteAcceptance(
          result: null,
          error: _badRequest('Akun ini sudah tergabung dengan bank sampah'),
        ),
        InviteAcceptance.otherBank,
      );
    });

    test('a bad or expired link is a rejection, not a membership claim', () {
      expect(
        classifyInviteAcceptance(
          result: null,
          error:
              _badRequest('Tautan undangan tidak valid atau sudah kedaluwarsa'),
        ),
        InviteAcceptance.rejected,
      );
    });

    test('an unreachable backend leaves the invite unspent', () {
      final acceptance = classifyInviteAcceptance(
        result: null,
        error: ConnectionTimeOutException(),
      );
      expect(acceptance, InviteAcceptance.failed);
      expect(
        acceptance.isTerminal,
        isFalse,
        reason: 'the token has not been consumed, so a retry is meaningful',
      );
    });

    test('every backend verdict is terminal', () {
      for (final acceptance in [
        InviteAcceptance.joined,
        InviteAcceptance.alreadyMember,
        InviteAcceptance.otherBank,
        InviteAcceptance.rejected,
      ]) {
        expect(acceptance.isTerminal, isTrue);
      }
    });
  });
}
