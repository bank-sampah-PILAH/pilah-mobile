import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_navigation_bar.dart';
import 'package:pilah_mobile/features/profile/presentation/pages/profile_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) =>
      BlocListener<AuthenticationBloc, AuthenticationStates>(
        listenWhen: (previous, current) {
          final oldRole =
              previous is Authenticated ? previous.authEntity.role : null;
          final newRole =
              current is Authenticated ? current.authEntity.role : null;
          return oldRole != newRole && RoleNavigationBar.supports(newRole);
        },
        listener: (_, __) => navigationShell.goBranch(0, initialLocation: true),
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
    final branches = RoleNavigationBar.branchIndicesFor(role);
    final selected = branches.indexOf(navigationShell.currentIndex);
    // The staff profile is outside its five navigation destinations.
    if (selected < 0 &&
        RoleNavigationBar.isStaff(role) &&
        navigationShell.currentIndex == 7) {
      return navigationShell;
    }
    // Nasabah may open the existing read-only schedule route outside the tabs.
    if (selected < 0 &&
        role == 'nasabah' &&
        navigationShell.currentIndex == 4) {
      return navigationShell;
    }
    if (selected < 0) {
      return Scaffold(
          body: Center(
              child: TextButton(
        onPressed: () => navigationShell.goBranch(0, initialLocation: true),
        child: const Text('Kembali ke Beranda'),
      )));
    }
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: RoleNavigationBar(
        role: role,
        currentIndex: selected,
        onSelected: (index) => navigationShell.goBranch(branches[index],
            initialLocation: index == selected),
      ),
    );
  }
}
