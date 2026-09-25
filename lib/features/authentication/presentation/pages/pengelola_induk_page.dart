import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/logout_events.dart';

class PengelolaIndukPage extends StatelessWidget {
  const PengelolaIndukPage({super.key});

  static const route = '/pengelola-induk';

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationStates>(
      listener: (context, state) {
        if (state is Unauthenticated) context.go('/login');
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Pengelola Induk')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Fitur Pengelola Induk belum tersedia.'),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () =>
                    context.read<AuthenticationBloc>().add(LogoutRequested()),
                child: const Text('Keluar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
