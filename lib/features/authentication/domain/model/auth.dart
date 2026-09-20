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
