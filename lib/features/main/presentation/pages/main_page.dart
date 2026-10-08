import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
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
import 'package:pilah_mobile/design/layout/content_bounds.dart';
import 'package:pilah_mobile/design/layout/navigation_form.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_navigation_bar.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_navigation_drawer.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_navigation_rail.dart';
import 'package:pilah_mobile/services/di.dart';

class MainPage extends StatelessWidget {
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
        child: _RoleShell(
            navigationShell: navigationShell, isWebOverride: isWebOverride),
      );
}

class _RoleShell extends StatelessWidget {
  const _RoleShell({required this.navigationShell, this.isWebOverride});
  final StatefulNavigationShell navigationShell;
  final bool? isWebOverride;

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
          bankSampahNama: session.authEntity.bankSampahNama,
          navigationShell: navigationShell,
          isWebOverride: isWebOverride,
        ),
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

class _ShellContent extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final approval =
        role == 'nasabah' ? context.watch<NasabahApprovalCubit>().state : null;
    final limitedNasabah = role == 'nasabah' &&
        !(approval is NasabahApprovalLoaded &&
            approval.memberships.any((membership) =>
                membership.status == MembershipStatus.approved &&
                membership.isActive));
    // Whether the cubit has actually confirmed limited access, as opposed to
    // `limitedNasabah` defaulting true while the initial load is still
    // pending. Only a confirmed status may discard the current route.
    final confirmedLimitedNasabah = role == 'nasabah' &&
        approval is NasabahApprovalLoaded &&
        limitedNasabah;
    final branches = RoleNavigationBar.branchIndicesFor(role,
        limitedNasabah: limitedNasabah);
    final selected = branches.indexOf(navigationShell.currentIndex);
    if (confirmedLimitedNasabah && selected < 0) {
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
    // coverage:ignore-start
    // Dead today: Jadwal (branch 4) is now one of the full nasabah tabs, so
    // `selected` is never negative there. Kept as a guard should it leave them.
    // Nasabah may open the existing read-only schedule route outside the tabs.
    if (selected < 0 &&
        role == 'nasabah' &&
        !limitedNasabah &&
        navigationShell.currentIndex == 4) {
      return navigationShell;
    }
    // coverage:ignore-end
    if (selected < 0 && !limitedNasabah) {
      return Scaffold(
          body: Center(
              child: TextButton(
        onPressed: () => navigationShell.goBranch(0, initialLocation: true),
        child: const Text('Kembali ke Beranda'),
      )));
    }
    final body = limitedNasabah && navigationShell.currentIndex != 7
        ? NasabahVerificationHome(name: name)
        : navigationShell;

    // Satu handler untuk kedua bentuk navigasi: keduanya melaporkan indeks
    // menu, jadi penerjemahan ke branch hanya ditulis sekali.
    void select(int index) {
      if (role == 'nasabah' && branches[index] == 0) {
        context.read<NasabahApprovalCubit>().load(silent: true);
      }
      navigationShell.goBranch(branches[index],
          initialLocation: index == selected);
    }

    final current = selected < 0 ? 0 : selected;

    // Platform menentukan keluarga bentuk navigasi, lebar hanya menentukan
    // seberapa banyak navigasi kiri yang muat. Role tetap menentukan
    // destinasinya, pada ketiga bentuk, dari sumber yang sama.
    final form = NavigationForm.resolve(
      isWeb: isWebOverride ?? kIsWeb,
      width: MediaQuery.sizeOf(context).width,
    );

    // Di aplikasi bottom bar dipertahankan apa adanya, termasuk seluruh
    // perilaku yang sudah dijaga test navigasi yang ada.
    if (form == NavigationForm.bottomBar) {
      return Scaffold(
        body: body,
        bottomNavigationBar: RoleNavigationBar(
          role: role,
          limitedNasabah: limitedNasabah,
          currentIndex: current,
          onSelected: select,
        ),
      );
    }

    // Browser sempit: destinasi pindah ke balik tombol menu. Kepala tipis
    // dipakai alih-alih AppBar milik Scaffold karena sebagian halaman membawa
    // AppBar sendiri, dan dua AppBar bertumpuk akan terlihat.
    if (form.isOverlay) {
      return Scaffold(
        drawer: RoleNavigationDrawer(
          role: role,
          limitedNasabah: limitedNasabah,
          currentIndex: current,
          bankSampahNama: bankSampahNama,
          onSelected: select,
        ),
        body: Column(
          children: [
            const _MenuButtonHeader(),
            Expanded(child: body),
          ],
        ),
      );
    }

    // Rail menggantikan bottom bar, tidak menemaninya: menampilkan keduanya
    // berarti menawarkan menu yang sama dua kali.
    return Scaffold(
      body: Row(
        children: [
          RoleNavigationRail(
            role: role,
            limitedNasabah: limitedNasabah,
            currentIndex: current,
            bankSampahNama: bankSampahNama,
            onSelected: select,
          ),
          Expanded(child: ContentBounds(child: body)),
        ],
      ),
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
