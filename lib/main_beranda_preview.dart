import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/riwayat/presentation/pages/nasabah_history_screen.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/profile/presentation/pages/profil_nasabah_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/beranda/presentation/pages/beranda_nasabah_page.dart';

/// Visual preview only. The normal app entrypoint still performs real login.
void main() {
  di.registerSingleton<NasabahRepository>(PreviewNasabahRepository());
  final router = GoRouter(initialLocation: AppLocations.dashboard, routes: [
    GoRoute(
        path: AppLocations.history,
        builder: (_, state) => NasabahHistoryScreen(
              membershipId: state.uri.queryParameters['keanggotaan_id'],
            )),
    GoRoute(
        path: AppLocations.dashboard,
        builder: (_, __) => const BerandaNasabahPage()),
    GoRoute(
        path: AppLocations.profile,
        builder: (_, __) => const ProfilNasabahPage()),
  ]);
  runApp(
    BlocProvider<AuthenticationBloc>(
      create: (_) => _PreviewAuthenticationBloc(),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'PILAH - Preview Beranda',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF166534)),
        ),
        routerConfig: router,
      ),
    ),
  );
}

/// Read-only sample session: no Firebase, API, or stored credentials.
class _PreviewAuthenticationBloc extends Cubit<AuthenticationStates>
    implements AuthenticationBloc {
  _PreviewAuthenticationBloc()
      : super(
          Authenticated(
            authEntity: const AuthEntity(
              id: 'preview-nasabah',
              name: 'Siti Aminah',
              email: 'preview@example.test',
              photoUrl: '',
              token: '',
              role: 'nasabah',
              nextStep: 'dashboard',
              bankSampahStatus: 'active',
              bankSampahNama: 'Bank Sampah Melati',
            ),
          ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
