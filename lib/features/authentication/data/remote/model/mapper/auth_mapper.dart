import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';

import '../responses/auth_response.dart';

class AuthMapper {
  static AuthEntity mapResponseToDomain(AuthResponse response) {
    return AuthEntity(
      id: response.id,
      name: response.name ?? '${response.firstName} ${response.lastName}'.trim(),
      email: response.email,
      photoUrl: response.photoUrl ?? response.image,
      token: response.accessToken,
      nextStep: response.nextStep,
    );
  }
}
