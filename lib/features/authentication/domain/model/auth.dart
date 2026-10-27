class AuthEntity {
  final String? id;
  final String name;
  final String email;
  final String photoUrl;
  final String token;
  final String? nextStep;
  final String? bankSampahNama;
  final String? bankSampahStatus; // pending | active | rejected | null
  final String? role;

  /// Backend-saved profile fields (empty/null when not yet filled). Lets
  /// complete_profile prefill from the account's actual data — e.g. a
  /// nasabah synced from a pengurus-entered record (PIL-154) — instead of
  /// always starting blank.
  final String noHp;
  final String jenisKelamin;
  final String? tanggalLahir;
  final String alamat;

  const AuthEntity({
    this.id,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.token,
    this.nextStep,
    this.bankSampahNama,
    this.bankSampahStatus,
    this.role,
    this.noHp = '',
    this.jenisKelamin = '',
    this.tanggalLahir,
    this.alamat = '',
  });
}

sealed class GoogleAuthOutcome {
  const GoogleAuthOutcome();
}

class GoogleSession extends GoogleAuthOutcome {
  final AuthEntity auth;

  const GoogleSession(this.auth);
}

class GoogleRegistrationRequired extends GoogleAuthOutcome {
  final String registrationToken;
  final int expiresIn;
  final String name;
  final String email;
  final String photoUrl;

  const GoogleRegistrationRequired({
    required this.registrationToken,
    required this.expiresIn,
    required this.name,
    required this.email,
    required this.photoUrl,
  });
}

enum GoogleRegistrationRole {
  nasabah('nasabah'),
  pengelola('pengelola'),
  pengelolaInduk('pengelola_induk');

  const GoogleRegistrationRole(this.wireValue);

  final String wireValue;
}
