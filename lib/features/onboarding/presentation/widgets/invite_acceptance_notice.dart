import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/invite_acceptance.dart';

/// Whether this account's *own* bank sampah registration is still awaiting
/// superadmin review.
///
/// Either signal is enough: [step] is the backend's routing verdict and reads
/// `approval_pending` once the profile is complete, while [bankSampahStatus]
/// still says `pending` in the window where onboarding routes on something else
/// (a profile saved moments ago, a cached entity not refreshed yet).
bool hasRegistrationUnderReview({
  required String? step,
  required String? bankSampahStatus,
}) =>
    step == 'approval_pending' || bankSampahStatus == 'pending';

/// Success copy for a redeemed invite, naming the bank sampah when the accept
/// response carried one.
///
/// The name comes from the response body rather than the cached session on
/// purpose: a user joining for the first time has no bank sampah on their
/// cached entity yet, and the refresh that would fill it is still in flight when
/// this is built. A blank name falls back to unnamed copy rather than rendering
/// "Bank Sampah " with nothing after it.
String joinedMessage(String? bankSampahNama) {
  final nama = bankSampahNama?.trim() ?? '';
  return nama.isEmpty
      ? 'Berhasil bergabung ke bank sampah'
      : 'Berhasil bergabung ke Bank Sampah $nama';
}

/// Raises the toast for [acceptance] on whichever screen the caller just routed
/// to.
///
/// Both invite entry points — the gate and the completion form in invite mode —
/// share it so the two never drift into telling the user different things about
/// the same backend answer.
///
/// [backendMessage] is only used for the outcomes with nothing better to say
/// than what the API reported; the membership cases have fixed copy.
///
/// [registrationUnderReview] narrows the [InviteAcceptance.otherBank] copy. The
/// backend refuses that case with one message whether the account runs a live
/// bank sampah or is merely waiting on approval for one it registered itself,
/// and "you are already a pengelola somewhere" reads as nonsense to someone who
/// has not been approved yet. See [hasRegistrationUnderReview].
/// [bankSampahNama] names the bank sampah in the join confirmation. See
/// [joinedMessage] for the blank-name fallback.
void showInviteAcceptanceNotice(
  InviteAcceptance acceptance, {
  required String backendMessage,
  bool registrationUnderReview = false,
  String? bankSampahNama,
}) {
  switch (acceptance) {
    case InviteAcceptance.joined:
      AppNotification.afterNavigation(
        (context) => AppNotification.showSuccess(
          context,
          title: 'Berhasil Bergabung',
          message: joinedMessage(bankSampahNama),
        ),
      );
      break;
    case InviteAcceptance.alreadyMember:
      // The neutral tone, and the reason it exists: the link worked and nothing
      // failed, but nothing happened either — the user was already where it was
      // taking them. Green would claim an act that never occurred, red would
      // report a problem that isn't one.
      AppNotification.afterNavigation(
        (context) => AppNotification.showWarning(
          context,
          title: 'Sudah Terdaftar',
          message: 'Anda sudah terdaftar pada bank sampah ini',
        ),
      );
      break;
    case InviteAcceptance.otherBank:
      AppNotification.afterNavigation(
        (context) => AppNotification.showError(
          context,
          title: registrationUnderReview
              ? 'Pengajuan Sedang Ditinjau'
              : 'Sudah Menjadi Pengelola',
          message: registrationUnderReview
              ? 'Tidak dapat bergabung, Anda masih memiliki pengajuan '
                  'pendaftaran bank sampah yang sedang ditinjau'
              : 'Kamu sudah menjadi pengelola di suatu bank sampah',
        ),
      );
      break;
    case InviteAcceptance.rejected:
      // A bad or expired link. Report it as what it is instead of implying
      // anything about the user's own membership.
      AppNotification.afterNavigation(
        (context) => AppNotification.showError(
          context,
          title: 'Tautan Undangan',
          message: backendMessage,
        ),
      );
      break;
    case InviteAcceptance.failed:
      AppNotification.afterNavigation(
        (context) => AppNotification.showError(
          context,
          title: 'Gagal Bergabung',
          message: backendMessage,
        ),
      );
      break;
  }
}
