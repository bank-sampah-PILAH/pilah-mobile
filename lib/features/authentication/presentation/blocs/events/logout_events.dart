import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';

/// Dispatched to sign the user out: revokes the refresh token server-side,
/// clears local tokens, and drives the bloc to [Unauthenticated].
class LogoutRequested extends AuthenticationEvent {}
