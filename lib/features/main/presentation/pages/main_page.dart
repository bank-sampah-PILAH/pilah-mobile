import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
// CI benchmark scratch edit: no behavior change.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_approval_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/states/nasabah_approval_state.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/nasabah_verification_home.dart';
import 'package:pilah_mobile/design/layout/navigation_form.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_destinations.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_navigation_bar.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_navigation_config.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_navigation_drawer.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_navigation_rail.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/web_content_surface.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/transaksi_baru_page.dart';

/// Indeks branch profil staff di `StatefulShellRoute`, di luar lima destinasi.
const _profileBranch = 7;
const _pengumumanBranch = 8;

class MainPage extends ConsumerWidget {
  const MainPage({
    super.key,
    required this.navigationShell,
    @visibleForTesting this.isWebOverride,
  });
  final StatefulNavigationShell navigationShell;

  /// Menggantikan [kIsWeb] pada test. kIsWeb adalah konstanta kompilasi dan
  /// selalu false di `flutter test`, jadi tanpa seam ini sisi web tidak dapat
  /// diuji sama sekali.
  final bool? isWebOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authenticationProvider, (previous, current) {
      if (current is Unauthenticated) {
        context.go(LoginPage.route);
        return;
      }
      final oldRole =
          previous is Authenticated ? previous.authEntity.role : null;
      final newRole = current is Authenticated ? current.authEntity.role : null;
      if (oldRole != newRole && RoleNavigationBar.supports(newRole)) {
        navigationShell.goBranch(0, initialLocation: true);
      }
    });
    return _RoleShell(
      navigationShell: navigationShell,
      isWebOverride: isWebOverride,
    );
  }
}

class _RoleShell extends ConsumerWidget {
  const _RoleShell({required this.navigationShell, this.isWebOverride});
  final StatefulNavigationShell navigationShell;
  final bool? isWebOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authenticationProvider);
    final role = auth is Authenticated ? auth.authEntity.role : null;
    if (!RoleNavigationBar.supports(role)) {
      // Fail closed either way. The message is for a signed-in account whose
      // role has no navigation; while signing out there is no account to
      // address, and the router is already on its way to the login page.
      return Scaffold(
          body: auth is Authenticated
              ? const Center(child: Text('Silakan masuk sebagai nasabah.'))
              : null);
    }
    if (role == 'nasabah') {
      final session = auth as Authenticated;
      return _ShellContent(
        role: role!,
        name: session.authEntity.name,
        bankSampahNama: session.authEntity.bankSampahNama,
        navigationShell: navigationShell,
        isWebOverride: isWebOverride,
      );
    }
    return _ShellContent(
      role: role!,
      bankSampahNama:
          auth is Authenticated ? auth.authEntity.bankSampahNama : null,
      navigationShell: navigationShell,
      isWebOverride: isWebOverride,
    );
  }
}

class _ShellContent extends ConsumerWidget {
  const _ShellContent({
    required this.role,
    required this.navigationShell,
    this.bankSampahNama,
    this.name = '',
    this.isWebOverride,
  });

  final String role;
  final String name;

  /// Bank sampah sesi ini, diteruskan ke rail sebagai konteks. Null bagi
  /// sesi yang tidak terikat bank sampah.
  final String? bankSampahNama;

  final StatefulNavigationShell navigationShell;

  final bool? isWebOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approval = _watchApproval(context, ref);
    final limitedNasabah = _isLimitedNasabah(approval);
    // Only a confirmed status may discard the current route; initial loading
    // must leave the current route intact.
    final confirmedLimitedNasabah = role == 'nasabah' &&
        approval is NasabahApprovalLoaded &&
        limitedNasabah;
    final form = NavigationForm.resolve(
      isWeb: isWebOverride ?? kIsWeb,
      width: MediaQuery.sizeOf(context).width,
    );
    final branches = RoleDestinations.branchIndicesFor(role,
        limitedNasabah: limitedNasabah,
        bottomBar: form == NavigationForm.bottomBar);
    final selected = branches.indexOf(navigationShell.currentIndex);
    if (confirmedLimitedNasabah && selected < 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) navigationShell.goBranch(0, initialLocation: true);
      });
    }
    final offDestination = _isOffDestination(selected, limitedNasabah);
    final routeGuard =
        _routeGuard(selected, limitedNasabah, offDestination, form);
    if (routeGuard != null) return routeGuard;

    final body =
        limitedNasabah && navigationShell.currentIndex != _profileBranch
            ? NasabahVerificationHome(name: name)
            : navigationShell;
    final select = _selectionHandler(ref, branches, selected);
    final railSelected = offDestination ? null : (selected < 0 ? 0 : selected);
    if (form == NavigationForm.bottomBar) {
      return _bottomBar(body, limitedNasabah, selected, select);
    }
    return _webShell(
      context,
      ref,
      body,
      limitedNasabah,
      railSelected,
      select,
      form,
    );
  }

  NasabahApprovalState? _watchApproval(BuildContext context, WidgetRef ref) {
    if (role != 'nasabah') return null;
    final approval = ref.watch(nasabahApprovalProvider);
    if (approval is NasabahApprovalInitial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted &&
            ref.read(nasabahApprovalProvider) is NasabahApprovalInitial) {
          ref.read(nasabahApprovalProvider.notifier).load();
        }
      });
    }
    return approval;
  }

  bool _isLimitedNasabah(NasabahApprovalState? approval) =>
      role == 'nasabah' &&
      !(approval is NasabahApprovalLoaded &&
          approval.memberships.any((membership) =>
              membership.status == MembershipStatus.approved &&
              membership.isActive));

  bool _isOffDestination(int selected, bool limitedNasabah) =>
      selected < 0 &&
      ((RoleNavigationBar.isStaff(role) &&
              (navigationShell.currentIndex == _profileBranch ||
                  navigationShell.currentIndex == _pengumumanBranch)) ||
          (role == 'nasabah' &&
              !limitedNasabah &&
              navigationShell.currentIndex == 4));

  Widget? _routeGuard(
    int selected,
    bool limitedNasabah,
    bool offDestination,
    NavigationForm form,
  ) {
    if (offDestination && form == NavigationForm.bottomBar) {
      return navigationShell;
    }
    if (selected < 0 && !limitedNasabah && !offDestination) {
      return Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => navigationShell.goBranch(0, initialLocation: true),
            child: const Text('Kembali ke Beranda'),
          ),
        ),
      );
    }
    return null;
  }

  ValueChanged<int> _selectionHandler(
    WidgetRef ref,
    List<int> branches,
    int selected,
  ) =>
      (index) {
        if (role == 'nasabah' && branches[index] == 0) {
          ref.read(nasabahApprovalProvider.notifier).load(silent: true);
        }
        navigationShell.goBranch(branches[index],
            initialLocation: index == selected);
      };

  Widget _bottomBar(
    Widget body,
    bool limitedNasabah,
    int selected,
    ValueChanged<int> onSelected,
  ) =>
      Scaffold(
        body: body,
        bottomNavigationBar: RoleNavigationBar(
          role: role,
          limitedNasabah: limitedNasabah,
          currentIndex: selected < 0 ? 0 : selected,
          onSelected: onSelected,
        ),
      );

  Widget _webShell(
    BuildContext context,
    WidgetRef ref,
    Widget body,
    bool limitedNasabah,
    int? selected,
    ValueChanged<int> onSelected,
    NavigationForm form,
  ) {
    final account = ref.watch(authenticationProvider);
    final profileName =
        account is Authenticated ? account.authEntity.name : null;
    final profileEmail =
        account is Authenticated ? account.authEntity.email : null;
    final routeInformationProvider =
        GoRouter.of(context).routeInformationProvider;
    return AnimatedBuilder(
      animation: routeInformationProvider,
      builder: (context, _) {
        final currentPath = routeInformationProvider.value.uri.path;
        final navigation = RoleNavigationConfig(
          role: role,
          limitedNasabah: limitedNasabah,
          currentIndex: selected,
          bankSampahNama: bankSampahNama,
          profileName: profileName,
          profileEmail: profileEmail,
          onProfile: () => navigationShell.goBranch(_profileBranch),
          onHome: () => navigationShell.goBranch(0, initialLocation: true),
          onAddTransaction: role == 'pengelola'
              ? () => context.push(TransaksiBaruPage.route)
              : null,
          transactionSelected: currentPath == TransaksiBaruPage.route,
          profileSelected: currentPath == AppLocations.profile,
          onSelected: onSelected,
        );
        if (form.isOverlay) {
          return Scaffold(
            drawer: RoleNavigationDrawer(navigation: navigation),
            body: Column(
              children: [
                const _MenuButtonHeader(),
                Expanded(child: body),
              ],
            ),
          );
        }
        return Scaffold(
          body: Row(
            children: [
              RoleNavigationRail(navigation: navigation),
              Expanded(child: WebContentSurface(child: body)),
            ],
          ),
        );
      },
    );
  }
}

/// Kepala tipis berisi tombol pembuka drawer, untuk browser sempit.
class _MenuButtonHeader extends StatelessWidget {
  const _MenuButtonHeader();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Buka menu navigasi',
          onPressed: Scaffold.of(context).openDrawer,
        ),
      ),
    );
  }
}
