import 'package:flutter/foundation.dart';
import '../domain/model/auth.dart';

class RoleSwitchSession {
  const RoleSwitchSession(this.auth, this.refreshToken);
  final AuthEntity auth;
  final String refreshToken;
}

/// Owns the ordered session transition. Observers consume progress and results.
class RoleSwitchCoordinator extends ChangeNotifier {
  RoleSwitchCoordinator({
    required this.readSession,
    required this.requestRole,
    required this.persistSession,
    required this.resetRoleState,
    required this.publishSession,
  });

  final AuthEntity? Function() readSession;
  final Future<RoleSwitchSession> Function(String role) requestRole;
  final Future<void> Function(String access, String refresh) persistSession;
  final VoidCallback resetRoleState;
  final ValueChanged<AuthEntity> publishSession;
  bool busy = false;
  String? error;
  AuthEntity? completedSession;

  Future<void> switchTo(String role) async {}
}
