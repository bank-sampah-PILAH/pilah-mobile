import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';

/// Dispatched on app start (from the splash screen) to restore a persisted
/// session before deciding where to route the user.
class CheckSessionRequested extends AuthenticationEvent {}
