import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';
import 'package:pilah_mobile/features/laporan/presentation/cubit/transaksi_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';

import 'core/router/app_router_config.dart';

class App extends StatelessWidget {
  const App({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<NasabahCubit>(
          create: (context) => NasabahCubit()..loadNasabah(),
        ),
        BlocProvider<HargaCubit>(
          create: (context) => HargaCubit()..loadHarga(),
        ),
        BlocProvider<TransaksiCubit>(
          create: (context) => TransaksiCubit()..loadTransaksi(),
        ),
      ],
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
    );
  }
}
