class AuthEntity {
  final int? id;
  final String name;
  final String email;
  final String photoUrl;
  final String token;

  const AuthEntity({
    this.id,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.token,
  });
}
