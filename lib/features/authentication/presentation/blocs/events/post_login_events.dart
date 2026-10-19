import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';

class PostLoginEvent implements AuthenticationEvent {
  final String email;
  final String password;

  const PostLoginEvent({
    required this.email,
    required this.password,
  });
}
