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
        !RoleSwitcher.isAvailableFor(state.authEntity)) {
      return const SizedBox.shrink();
    }
    return RoleSwitcher(
        auth: state.authEntity, coordinator: ref.watch(roleSwitchProvider));
  }
}

class RoleSwitcher extends StatelessWidget {
  const RoleSwitcher(
      {super.key, required this.auth, required this.coordinator});
  final AuthEntity auth;
  final RoleSwitchCoordinator coordinator;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: coordinator, builder: (context, _) => _content(context));

  static bool isAvailableFor(AuthEntity? auth) =>
      auth != null &&
      const ['pengelola', 'nasabah'].contains(auth.role) &&
      auth.ownedRoles.length > 1;

  Widget _content(BuildContext context) {
    final target = auth.role == 'pengelola' ? 'nasabah' : 'pengelola';
    final label = target == 'nasabah' ? 'Nasabah' : 'Pengurus';
    final controller = coordinator;
    final error = controller.error;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          label: 'Pindah Role ke $label',
          icon: Icons.swap_horiz,
          isLoading: controller.busy,
          onPressed: controller.busy ? null : () => controller.switchTo(target),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(error, semanticsLabel: error),
          ),
      ],
    );
  }
}
