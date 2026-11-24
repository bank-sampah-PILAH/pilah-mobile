import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/router/auth_routing.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import '../providers/authentication_provider.dart';
import '../providers/role_switch_provider.dart';
import '../states/authentication_states.dart';

class RoleSwitchObserver extends ConsumerWidget {
  const RoleSwitchObserver({super.key, required this.child,
    required this.navigate, this.onError});
  final Widget child;
  final void Function(String location) navigate;
  final void Function(String message)? onError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authenticationProvider);
    if (auth is Authenticated && auth.authEntity.ownedRoles.length > 1) {
      ref.listen(roleSwitchProvider, (_, coordinator) {
        if (!coordinator.busy && coordinator.error != null) {
          final message = coordinator.error!;
          if (onError != null) {
            onError!(message);
          } else {
            AppNotification.afterNavigation((context) =>
                AppNotification.showError(context,
                    title: 'Gagal mengganti role', message: message));
          }
        }
        final completed = coordinator.completedSession;
        if (!coordinator.busy && completed != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            final live = ref.read(authenticationProvider);
            if (live is! Authenticated || live.authEntity != completed) return;
            navigate(locationForAuthStep(completed.nextStep, role: completed.role));
          });
        }
      });
    }
    return child;
  }
}
