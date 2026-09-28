import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_cubit.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_state.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/nasabah_verification_home.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_navigation_bar.dart';
import 'package:pilah_mobile/services/di.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) =>
      BlocListener<AuthenticationBloc, AuthenticationStates>(
        listenWhen: (previous, current) {
          if (current is Unauthenticated) return true;
          final oldRole =
              previous is Authenticated ? previous.authEntity.role : null;
          final newRole =
              current is Authenticated ? current.authEntity.role : null;
          return oldRole != newRole && RoleNavigationBar.supports(newRole);
        },
        listener: (context, state) {
          if (state is Unauthenticated) {
            context.go(LoginPage.route);
            return;
          }
          navigationShell.goBranch(0, initialLocation: true);
        },
        child: _RoleShell(navigationShell: navigationShell),
      );
}

class _RoleShell extends StatelessWidget {
  const _RoleShell({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthenticationBloc>().state;
    final role = auth is Authenticated ? auth.authEntity.role : null;
    if (!RoleNavigationBar.supports(role)) {
      return const Scaffold(
          body: Center(child: Text('Silakan masuk sebagai nasabah.')));
    }
    if (role == 'nasabah') {
      final session = auth as Authenticated;
      return BlocProvider<NasabahApprovalCubit>(
        key: ValueKey((
          session.authEntity.id,
          session.authEntity.email,
          session.authEntity.token
        )),
        create: (_) => di<NasabahApprovalCubit>()..load(),
        child: _ShellContent(
          role: role!,
          name: session.authEntity.name,
          navigationShell: navigationShell,
        ),
      );
    }
    return _ShellContent(role: role!, navigationShell: navigationShell);
  }
}

class _ShellContent extends StatelessWidget {
  const _ShellContent({
    required this.role,
    required this.navigationShell,
    this.name = '',
  });

  final String role;
  final String name;
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final approval =
        role == 'nasabah' ? context.watch<NasabahApprovalCubit>().state : null;
    final limitedNasabah = role == 'nasabah' &&
        !(approval is NasabahApprovalLoaded &&
            approval.memberships.any((membership) =>
                membership.status == MembershipStatus.approved &&
                membership.isActive));
    final branches = RoleNavigationBar.branchIndicesFor(role,
        limitedNasabah: limitedNasabah);
    final selected = branches.indexOf(navigationShell.currentIndex);
    if (limitedNasabah && selected < 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) navigationShell.goBranch(0, initialLocation: true);
      });
    }
    // The staff profile is outside its five navigation destinations.
    if (selected < 0 &&
        RoleNavigationBar.isStaff(role) &&
        navigationShell.currentIndex == 7) {
      return navigationShell;
    }
    // Nasabah may open the existing read-only schedule route outside the tabs.
    if (selected < 0 &&
        role == 'nasabah' &&
        !limitedNasabah &&
        navigationShell.currentIndex == 4) {
      return navigationShell;
    }
    if (selected < 0 && !limitedNasabah) {
      return Scaffold(
          body: Center(
              child: TextButton(
        onPressed: () => navigationShell.goBranch(0, initialLocation: true),
        child: const Text('Kembali ke Beranda'),
      )));
    }
    return Scaffold(
      body: limitedNasabah && navigationShell.currentIndex != 7
          ? NasabahVerificationHome(name: name)
          : navigationShell,
      bottomNavigationBar: RoleNavigationBar(
        role: role,
        limitedNasabah: limitedNasabah,
        currentIndex: selected < 0 ? 0 : selected,
        onSelected: (index) {
          if (role == 'nasabah' && branches[index] == 0) {
            context.read<NasabahApprovalCubit>().load(silent: true);
          }
          navigationShell.goBranch(branches[index],
              initialLocation: index == selected);
        },
      ),
    );
  }
}
