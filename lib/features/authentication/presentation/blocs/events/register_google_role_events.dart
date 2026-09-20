import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';

class RegisterGoogleRoleRequested extends AuthenticationEvent {
  final String role;

  const RegisterGoogleRoleRequested({required this.role});
}

class ChangeGoogleAccountRequested extends AuthenticationEvent {
  const ChangeGoogleAccountRequested();
}
