import 'package:dartz/dartz.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/riwayat/domain/entities/riwayat_entities.dart';
import 'package:pilah_mobile/features/riwayat/domain/repositories/riwayat_repository.dart';
import 'package:pilah_mobile/features/riwayat/domain/use_cases/riwayat_use_cases.dart';
import 'package:pilah_mobile/features/riwayat/presentation/cubit/riwayat_history_cubit.dart';
import 'package:pilah_mobile/features/riwayat/presentation/pages/nasabah_history_screen.dart';
import 'package:pilah_mobile/preview/preview_authentication.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/profile/presentation/pages/profil_nasabah_page.dart';
import 'package:pilah_mobile/services/di.dart';

import 'package:pilah_mobile/features/beranda/presentation/pages/beranda_nasabah_page.dart';

/// Visual preview only. The normal app entrypoint still performs real login.
void main() {
  if (!di.isRegistered<NasabahRepository>()) {
    di.registerSingleton<NasabahRepository>(PreviewNasabahRepository());
  }
  // The history screen's setoran tab resolves the cubit from GetIt; preview
  // runs offline without configureDependencies, so wire offline stubs.
  if (!di.isRegistered<RiwayatRepository>()) {
    di.registerFactory<RiwayatRepository>(() => _PreviewRiwayatRepository());
    di.registerFactory<RiwayatHistoryCubit>(
      () => RiwayatHistoryCubit(
        GetRiwayatHistoryUseCase(di<RiwayatRepository>()),
        GetRiwayatSetoranDetailUseCase(di<RiwayatRepository>()),
      ),
    );
  }
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

/// Offline riwayat stub: empty history, no detail, no PDF — matching the
/// design-preview contract of [PreviewNasabahRepository].
class _PreviewRiwayatRepository implements RiwayatRepository {
  @override
  Future<Either<NetworkException, RiwayatHistory>> history(
    String membershipId, {
    int page = 1,
  }) async =>
      Right(const RiwayatHistory([], false));

  @override
  Future<Either<NetworkException, RiwayatSetoranDetail>> setoranDetail(
    String membershipId,
    String transactionId,
  ) async =>
      Left(NetworkException(message: 'Pratinjau tidak memiliki data detail.'));

  @override
  Future<Either<NetworkException, RiwayatPdf>> exportPdf(
    String membershipId,
  ) async =>
      Left(NetworkException(message: 'Pratinjau tidak dapat membuat PDF.'));
}
