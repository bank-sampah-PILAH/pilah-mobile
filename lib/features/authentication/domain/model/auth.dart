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
