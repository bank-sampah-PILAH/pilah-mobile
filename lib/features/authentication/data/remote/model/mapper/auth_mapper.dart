import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';

import '../responses/auth_response.dart';

class AuthMapper {
  static AuthEntity mapResponseToDomain(AuthResponse response) {
    return AuthEntity(
      id: response.user.id,
      name: response.user.name,
      email: response.user.email,
      photoUrl: 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(response.user.name)}', // Fallback photo since Django doesn't store it
      token: response.accessToken,
      nextStep: response.nextStep,
      bankSampahNama: response.user.bankSampahNama,
      role: response.user.role,
    );
  }

  /// Maps the `GET /auth/me` payload to an [AuthEntity] for session restore.
  ///
  /// Unlike the login envelope, this endpoint returns the user fields flat with
  /// `nama` (no `name`) and exposes the routing hint as `state` (not
  /// `next_step`), and it carries no token — the session token is already
  /// persisted, so [AuthEntity.token] is left empty here.
  static AuthEntity mapMeResponseToDomain(Map<String, dynamic> json) {
    final name = (json['nama'] ?? json['name'] ?? '').toString();
    return AuthEntity(
      id: json['id']?.toString(),
      name: name,
      email: json['email']?.toString() ?? '',
      photoUrl: 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}',
      token: '',
      nextStep: (json['state'] ?? json['next_step'])?.toString(),
      bankSampahNama: json['bank_sampah_nama']?.toString(),
      role: json['role']?.toString(),
    );
  }
}
