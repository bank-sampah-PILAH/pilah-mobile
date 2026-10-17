import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';

/// Dispatched to sign the user out: on web, clears Google's auto-select state
/// (best effort), revokes the refresh token, clears local tokens, and drives
/// the bloc to [Unauthenticated].
class LogoutRequested extends AuthenticationEvent {}
