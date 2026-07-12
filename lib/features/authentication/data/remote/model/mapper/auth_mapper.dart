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
    );
  }
}
