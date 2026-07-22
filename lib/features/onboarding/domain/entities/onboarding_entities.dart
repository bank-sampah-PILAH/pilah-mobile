// Request/result models for the real onboarding endpoints
// (PUT /onboarding/profile, POST /onboarding/bank-sampah).

class CompleteProfileRequest {
  final String nama;

  /// Backend enum value: `laki-laki` or `perempuan`.
  final String jenisKelamin;

  /// ISO date, `yyyy-MM-dd`.
  final String tanggalLahir;

  /// Local number digits (e.g. `81234567890`); the backend normalizes it.
  final String noHp;

  const CompleteProfileRequest({
    required this.nama,
    required this.jenisKelamin,
    required this.tanggalLahir,
    required this.noHp,
  });

  Map<String, dynamic> toJson() => {
        'nama': nama,
        'jenis_kelamin': jenisKelamin,
        'tanggal_lahir': tanggalLahir,
        'no_hp': noHp,
      };
}

class RegisterBankSampahRequest {
  final String nama;
  final String alamat;
  final String? kota;
  final String noHpPic;

  /// Absolute path to the selected `foto_kegiatan` image (sent as multipart).
  final String fotoKegiatanPath;

  const RegisterBankSampahRequest({
    required this.nama,
    required this.alamat,
    this.kota,
    required this.noHpPic,
    required this.fotoKegiatanPath,
  });
}

/// Outcome of an onboarding step: the backend's next routing hint, plus the
/// discriminator `POST /invites/accept` uses to say something happened that was
/// neither a join nor an error.
class OnboardingResult {
  final String? nextStep;

  /// `outcome` from a 200 response — `already_member` when the account is
  /// already on the bank sampah the invite points at. Absent on the endpoints
  /// that have nothing to disambiguate.
  final String? outcome;

  /// `message` from a 200 response, e.g. "Anda sudah terdaftar pada bank sampah
  /// ini". Kept as the fallback signal for [isAlreadyMember]: the wording is
  /// the only thing a deployment without `outcome` gives us.
  final String? message;

  /// Name of the bank sampah the call concerned, for copy that names it.
  ///
  /// Only populated where the response body actually describes a bank sampah —
  /// `POST /invites/accept` serialises one, so its `nama` is the inviting bank.
  /// `PUT /onboarding/profile` also returns a `nama`, but that one is the
  /// *user's*, which is why this is filled per-endpoint rather than by a shared
  /// mapper.
  final String? bankSampahNama;

  const OnboardingResult({
    this.nextStep,
    this.outcome,
    this.message,
    this.bankSampahNama,
  });

  /// Whether a *successful* accept-invite call actually meant "you were already
  /// on this bank sampah".
  ///
  /// This case does not come back as an error. The deployed API answers
  /// **HTTP 200** with `{"outcome": "already_member", "message": "Anda sudah
  /// terdaftar pada bank sampah ini"}`, which is indistinguishable from a fresh
  /// join unless the body is read — the app used to keep only `next_step` and
  /// so reported it as a successful join.
  bool get isAlreadyMember {
    if (outcome != null) {
      return outcome!.trim().toLowerCase() == 'already_member';
    }
    return message?.toLowerCase().contains('sudah terdaftar') ?? false;
  }
}
