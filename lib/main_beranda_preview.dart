import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/beranda/presentation/pages/beranda_nasabah_page.dart';

/// Visual preview only. The normal app entrypoint still performs real login.
void main() {
  runApp(
    BlocProvider<AuthenticationBloc>(
      create: (_) => _PreviewAuthenticationBloc(),
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
