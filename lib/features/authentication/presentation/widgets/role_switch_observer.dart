import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/router/auth_routing.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import '../../application/role_switch_coordinator.dart';
import '../providers/authentication_provider.dart';
import '../providers/role_switch_provider.dart';
import '../states/authentication_states.dart';

class RoleSwitchObserver extends ConsumerWidget {
  const RoleSwitchObserver(
      {super.key, required this.child, required this.navigate, this.onError});
  final Widget child;
  final void Function(String location) navigate;
  final void Function(String message)? onError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authenticationProvider);
    if (auth is! Authenticated || auth.authEntity.ownedRoles.length < 2) {
      return child;
    }
    ref.listen(roleSwitchProvider,
        (_, coordinator) => _handleSwitch(context, ref, coordinator));
    return child;
  }

  void _handleSwitch(
      BuildContext context, WidgetRef ref, RoleSwitchCoordinator coordinator) {
    if (coordinator.busy) return;
    final error = coordinator.error;
    if (error != null) _showError(error);
    final completed = coordinator.completedSession;
    if (completed == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final live = ref.read(authenticationProvider);
      if (live is! Authenticated || live.authEntity != completed) return;
      navigate(locationForAuthStep(completed.nextStep, role: completed.role));
    });
  }

  void _showError(String message) {
    final reportError = onError;
    if (reportError != null) {
      reportError(message);
      return;
    }
    AppNotification.afterNavigation((context) => AppNotification.showError(
        context,
        title: 'Gagal mengganti role',
        message: message));
  }
}
