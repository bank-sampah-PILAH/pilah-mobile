import 'package:equatable/equatable.dart';

import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';

abstract class AuthenticationStates extends Equatable {}

class AuthenticationInitial extends AuthenticationStates {
  @override
  List<Object?> get props => [];
}

class AuthenticationLoading extends AuthenticationStates {
  @override
  List<Object?> get props => [];
}

/// Emitted when no valid session could be restored (no token, or the token was
/// rejected by `GET /auth/me`), and after an explicit logout.
class Unauthenticated extends AuthenticationStates {
  @override
  List<Object?> get props => [];
}

class Authenticated extends AuthenticationStates {
  final AuthEntity authEntity;

  Authenticated({required this.authEntity});

  @override
  List<Object?> get props => [authEntity];
}

class GoogleRegistrationPending extends AuthenticationStates {
  final GoogleRegistrationRequired registration;

  GoogleRegistrationPending({required this.registration});

  @override
  List<Object?> get props => [registration];
}

class GoogleRegistrationSubmitting extends AuthenticationStates {
  final GoogleRegistrationRequired registration;
  final String role;

  GoogleRegistrationSubmitting({
    required this.registration,
    required this.role,
  });

  @override
  List<Object?> get props => [registration, role];
}

class GoogleRegistrationFailure extends AuthenticationStates {
  final GoogleRegistrationRequired registration;
  final String message;

  GoogleRegistrationFailure({
    required this.registration,
    required this.message,
  });

  @override
  List<Object?> get props => [registration, message];
}

class GoogleRegistrationExpired extends AuthenticationStates {
  final String message;

  GoogleRegistrationExpired({required this.message});

  @override
  List<Object?> get props => [message];
}

class AuthenticationFailure extends AuthenticationStates {
  final String message;

  AuthenticationFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
