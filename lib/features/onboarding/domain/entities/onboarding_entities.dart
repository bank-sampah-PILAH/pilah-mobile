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

  /// Required for a nasabah account, ignored by the backend for every other
  /// role. Empty when this account isn't nasabah.
  final String alamat;

  const CompleteProfileRequest({
    required this.nama,
    required this.jenisKelamin,
    required this.tanggalLahir,
    required this.noHp,
    this.alamat = '',
  });

  Map<String, dynamic> toJson() => {
        'nama': nama,
        'jenis_kelamin': jenisKelamin,
        'tanggal_lahir': tanggalLahir,
        'no_hp': noHp,
        if (alamat.trim().isNotEmpty) 'alamat': alamat,
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

/// A bank sampah a calon nasabah can apply to join, as listed by
/// `GET /bank-sampah` (PIL-204's picker).
class BankSampahDirectoryEntity {
  final String id;
  final String nama;
  final String alamat;
  final String kota;
  final String fotoLogo;

  const BankSampahDirectoryEntity({
    required this.id,
    required this.nama,
    required this.alamat,
    required this.kota,
    required this.fotoLogo,
  });

  factory BankSampahDirectoryEntity.fromJson(Map<String, dynamic> json) =>
      BankSampahDirectoryEntity(
        id: json['id']?.toString() ?? '',
        nama: json['nama']?.toString() ?? '',
        alamat: (json['alamat'] as String?) ?? '',
        kota: (json['kota'] as String?) ?? '',
        fotoLogo: (json['foto_logo'] as String?) ?? '',
      );
}

/// One row from `GET /nasabah/me`: a calon/active nasabah's own membership.
/// Used by the bank-sampah picker (PIL-204) to show what's already joined
/// and lock further registrations under the current one-membership-per-
/// nasabah scope.
class NasabahMembershipEntity {
  final String id;
  final String bankSampahId;
  final String bankSampahNama;
  final String bankSampahKota;

  /// Backend enum value: `pending`, `approved`, or `rejected`.
  final String status;
  final bool isActive;

  const NasabahMembershipEntity({
    required this.id,
    required this.bankSampahId,
    required this.bankSampahNama,
    required this.bankSampahKota,
    required this.status,
    required this.isActive,
  });

  factory NasabahMembershipEntity.fromJson(Map<String, dynamic> json) {
    final bank = json['bank_sampah'] as Map<String, dynamic>? ?? const {};
    return NasabahMembershipEntity(
      id: json['id']?.toString() ?? '',
      bankSampahId: bank['id']?.toString() ?? '',
      bankSampahNama: bank['nama']?.toString() ?? '',
      bankSampahKota: bank['kota']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      isActive: json['is_active'] as bool? ?? false,
    );
  }
}

/// Input for `POST /onboarding/nasabah`: a calon nasabah applying to join
/// [bankSampahId]. `nama`/`jenis_kelamin`/`tanggal_lahir`/`no_hp`/`alamat`
/// are not asked for again here — the backend copies them from the profile
/// completed on the shared `complete_profile` step.
class RegisterNasabahRequest {
  final String bankSampahId;

  const RegisterNasabahRequest({required this.bankSampahId});

  Map<String, dynamic> toJson() => {'bank_sampah_id': bankSampahId};

  // Value equality so a mocktail `verify` can match a request rebuilt from
  // form state against the fresh instance the screen actually sent, instead
  // of requiring the exact same object reference.
  @override
  bool operator ==(Object other) =>
      other is RegisterNasabahRequest && other.bankSampahId == bankSampahId;

  @override
  int get hashCode => bankSampahId.hashCode;
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
