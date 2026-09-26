import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/preview/preview_authentication.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';

import 'package:pilah_mobile/features/beranda/presentation/pages/beranda_nasabah_page.dart';

/// Visual preview only. The normal app entrypoint still performs real login.
void main() {
  runApp(
    BlocProvider<AuthenticationBloc>(
      create: (_) => createPreviewAuthenticationBloc(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'PILAH - Preview Beranda',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF166534)),
        ),
        home: const BerandaNasabahPage(),
      ),
    ),
  );
}
