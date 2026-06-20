import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';

import '../../../domain/model/auth.dart';

class PostLoginInitState extends AuthenticationStates {
  @override
  List<Object?> get props => [];
}

class PostLoginLoadingState extends AuthenticationStates {
  @override
  List<Object?> get props => [];
}

class PostLoginSuccessState extends AuthenticationStates {
  final AuthEntity auth;

  PostLoginSuccessState({required this.auth});

  @override
  List<Object?> get props => [auth];
}

class PostLoginErrorState extends AuthenticationStates {
  final String message;

  PostLoginErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}
