import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';

/// Re-fetches `GET /auth/me` to refresh the in-memory user without a full
/// re-login. Dispatched after the user changes server-side profile data (e.g.
/// completing their profile name, or registering a bank sampah), so the
/// dashboard/profile reflect the entered name instead of the stale Google one.
class RefreshUserRequested extends AuthenticationEvent {}
