import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';

class LoginWithGoogleRequested extends AuthenticationEvent {
  final String idToken;

  LoginWithGoogleRequested({required this.idToken});
}
