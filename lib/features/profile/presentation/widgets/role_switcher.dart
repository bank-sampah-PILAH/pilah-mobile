import 'package:flutter/material.dart';
import 'package:pilah_mobile/features/authentication/application/role_switch_coordinator.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/role_switch_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';

class ConnectedRoleSwitcher extends ConsumerWidget {
  const ConnectedRoleSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authenticationProvider);
    if (state is! Authenticated ||
        !const ['pengelola', 'nasabah'].contains(state.authEntity.role)) {
      return const SizedBox.shrink();
    }
    final auth = state.authEntity;
    return RoleSwitcher(auth: auth, coordinator: auth.ownedRoles.length > 1
        ? ref.watch(roleSwitchProvider) : null);
  }
}

class RoleSwitcher extends StatelessWidget {
  const RoleSwitcher({super.key, required this.auth, this.coordinator});
  final AuthEntity auth;
  final RoleSwitchCoordinator? coordinator;

  @override
  Widget build(BuildContext context) {
    final controller = coordinator;
    return controller == null ? _content(context) : AnimatedBuilder(
      animation: controller, builder: (context, _) => _content(context));
  }

  Widget _content(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Role saya', style: Theme.of(context).textTheme.titleMedium),
        for (final role in const ['pengelola', 'nasabah'])
          if (auth.ownedRoles.contains(role))
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(role == 'nasabah' ? 'Nasabah' : 'Pengurus'),
              subtitle: role == auth.role ? const Text('Aktif') : null,
              trailing: role == auth.role ? const Icon(Icons.check_circle_outline)
                  : AppButton(label: 'Gunakan role ini',
                      expand: false,
                      variant: AppButtonVariant.outlined,
                      onPressed: coordinator == null || coordinator!.busy
                          ? null : () => coordinator!.switchTo(role)),
            ),
        if (coordinator?.busy == true)
          const LinearProgressIndicator(semanticsLabel: 'Mengganti role'),
        if (coordinator?.error != null)
          Text(coordinator!.error!, semanticsLabel: coordinator!.error),
      ]),
    ),
  );
}
