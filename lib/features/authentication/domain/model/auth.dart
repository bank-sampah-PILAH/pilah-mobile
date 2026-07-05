class AuthEntity {
  final String? id;
  final String name;
  final String email;
  final String photoUrl;
  final String token;
  final String? nextStep;

  const AuthEntity({
    this.id,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.token,
    this.nextStep,
  });
}
