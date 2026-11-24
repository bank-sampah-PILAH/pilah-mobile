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
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> switchTo(String role) async {
    if (busy || _disposed) return;
    final current = readSession();
    if (current == null || current.role == role ||
        !current.ownedRoles.contains(role) ||
        !const ['pengelola', 'nasabah'].contains(role)) return;
    busy = true;
    error = null;
    completedSession = null;
    notifyListeners();
    try {
      final next = await requestRole(role);
      final live = readSession();
      if (_disposed || live == null || live.id != current.id ||
          live.role != current.role || live.token != current.token) return;
      final allowedSteps = role == 'nasabah'
          ? const ['nasabah_dashboard', 'register_nasabah', 'complete_profile']
          : const ['dashboard', 'approval_pending', 'registration_rejected',
              'register_bank_sampah', 'complete_profile'];
      if (next.auth.id != current.id || current.id == null ||
          next.auth.role != role || next.auth.token.trim().isEmpty ||
          next.refreshToken.trim().isEmpty ||
          !allowedSteps.contains(next.auth.nextStep)) {
        throw const FormatException('Invalid role switch session');
      }
      await persistSession(next.auth.token, next.refreshToken);
      final afterSave = readSession();
      if (_disposed || afterSave == null || afterSave.id != current.id ||
          afterSave.role != current.role || afterSave.token != current.token) return;
      resetRoleState();
      final auth = next.auth.roles.isEmpty
          ? next.auth.withRoles(current.ownedRoles) : next.auth;
      publishSession(auth);
      completedSession = auth;
    } catch (_) {
      error = 'Gagal mengganti role. Role sebelumnya tetap aktif. '
          'Periksa koneksi dan coba lagi.';
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }
}
