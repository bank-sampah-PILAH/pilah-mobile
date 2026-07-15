import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';

import 'package:pilah_mobile/services/di.dart';
import 'core/router/app_router_config.dart';

class App extends StatelessWidget {
  const App({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Cubits load their data from each page's initState (post-login), so
        // the requests carry the authenticated session instead of firing once
        // at cold start before a token exists.
        BlocProvider<NasabahCubit>(
          create: (context) => di<NasabahCubit>(),
        ),
        BlocProvider<HargaCubit>(
          create: (context) => di<HargaCubit>(),
        ),
        BlocProvider<TransaksiCubit>(
          create: (context) => di<TransaksiCubit>(),
        ),
        BlocProvider<DashboardCubit>(
          create: (context) => di<DashboardCubit>(),
        ),
        BlocProvider<AuthenticationBloc>(
          create: (context) => di<AuthenticationBloc>(),
        ),
        BlocProvider<OnboardingCubit>(
          create: (context) => di<OnboardingCubit>(),
        ),
      ],
      // Session hygiene for the app-scoped (@lazySingleton) cubits. These
      // outlive any one session, so without this the next user to log in
      // inherits the previous one's cached lists and stats.
      //
      // It lives at the root, above the router, on purpose: `Unauthenticated`
      // is emitted by an explicit logout *and* by a rejected/expired session on
      // startup, from whichever screen happens to be on top. A listener tied to
      // a single page only runs while that page is mounted, which silently
      // misses every other exit path.
      child: BlocListener<AuthenticationBloc, AuthenticationStates>(
        listenWhen: (previous, current) => current is Unauthenticated,
        listener: (context, state) => _resetSessionScopedCubits(context),
        child: MaterialApp.router(
          title: 'Flutter Pilah Mobile',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
            ),
            useMaterial3: true,
          ),
          routerConfig: AppRouterConfig.getRouter(),
        ),
      ),
    );
  }

  void _resetSessionScopedCubits(BuildContext context) {
    context.read<NasabahCubit>().reset();
    context.read<HargaCubit>().reset();
    context.read<TransaksiCubit>().reset();
    context.read<DashboardCubit>().reset();
  }
}
