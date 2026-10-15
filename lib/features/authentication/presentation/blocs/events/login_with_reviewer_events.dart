import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';

class LoginWithReviewerRequested extends AuthenticationEvent {
  final String email;
  final String password;

  const LoginWithReviewerRequested({
    required this.email,
    required this.password,
  });
}
