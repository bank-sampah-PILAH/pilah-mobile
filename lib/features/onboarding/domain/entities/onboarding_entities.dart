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

/// Outcome of an onboarding step: the backend's next routing hint.
class OnboardingResult {
  final String? nextStep;

  const OnboardingResult({this.nextStep});
}
