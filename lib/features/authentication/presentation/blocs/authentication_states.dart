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

class AuthenticationFailure extends AuthenticationStates {
  final String message;

  AuthenticationFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
