import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';

class RegisterGoogleRoleRequested extends AuthenticationEvent {
  final GoogleRegistrationRole role;

  const RegisterGoogleRoleRequested({required this.role});
}

class ChangeGoogleAccountRequested extends AuthenticationEvent {
  const ChangeGoogleAccountRequested();
}
