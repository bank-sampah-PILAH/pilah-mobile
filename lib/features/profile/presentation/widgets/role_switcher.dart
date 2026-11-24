import 'package:flutter/material.dart';
import 'package:pilah_mobile/features/authentication/application/role_switch_coordinator.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';

class RoleSwitcher extends StatelessWidget {
  const RoleSwitcher({super.key, required this.auth, this.coordinator});
  final AuthEntity auth;
  final RoleSwitchCoordinator? coordinator;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
