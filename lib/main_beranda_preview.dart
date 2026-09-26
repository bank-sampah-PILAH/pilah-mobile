import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/profile/presentation/pages/profil_nasabah_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/preview/preview_authentication.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';

import 'package:pilah_mobile/features/beranda/presentation/pages/beranda_nasabah_page.dart';

/// Visual preview only. The normal app entrypoint still performs real login.
void main() {
  di.registerSingleton<NasabahRepository>(PreviewNasabahRepository());
  final router = GoRouter(initialLocation: AppLocations.dashboard, routes: [
    GoRoute(
        path: AppLocations.dashboard,
        builder: (_, __) => const BerandaNasabahPage()),
    GoRoute(
        path: AppLocations.profile,
        builder: (_, __) => const ProfilNasabahPage()),
  ]);
  runApp(
    BlocProvider<AuthenticationBloc>(
      create: (_) => createPreviewAuthenticationBloc(),
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
