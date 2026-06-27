import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';

class LoginWithGoogleRequested extends AuthenticationEvent {
  final String name;
  final String email;
  final String photoUrl;
  final String idToken;

  LoginWithGoogleRequested({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.idToken,
  });
}
