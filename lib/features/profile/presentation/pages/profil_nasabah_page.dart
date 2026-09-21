import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';

/// Read-only personal identity from the current session, without admin APIs.
class ProfilNasabahPage extends StatelessWidget {
  const ProfilNasabahPage({super.key});

  TextStyle _text(double size,
          {FontWeight weight = FontWeight.w400,
          Color color = const Color(0xFF0F172A)}) =>
      TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.45,
      );

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AuthenticationBloc, AuthenticationStates>(
        builder: (context, state) {
          final auth = state is Authenticated ? state.authEntity : null;
          final name = auth?.name.trim() ?? '';
          final email = auth?.email.trim() ?? '';
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              backgroundColor: const Color(0xFFF8FAFC),
              surfaceTintColor: Colors.transparent,
              title: Text('Profil', style: _text(20, weight: FontWeight.w700)),
              leading: IconButton(
                  tooltip: 'Kembali ke Beranda',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/dashboard');
                    }
                  }),
            ),
            body: SafeArea(
                child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              if (auth?.role != 'nasabah')
                                Text('Silakan masuk untuk melihat profil Anda.',
                                    style: _text(15))
                              else ...[
                                Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                            color: const Color(0xFFE2E8F0))),
                                    child: Column(children: [
                                      CircleAvatar(
                                          radius: 36,
                                          backgroundColor:
                                              const Color(0xFFD1FAE5),
                                          child: Text(
                                              name.isEmpty
                                                  ? 'N'
                                                  : name.characters.first
                                                      .toUpperCase(),
                                              style: _text(28,
                                                  weight: FontWeight.w700,
                                                  color: const Color(
                                                      0xFF047857)))),
                                      const SizedBox(height: 16),
                                      Text(
                                          name.isEmpty
                                              ? 'Nama belum tersedia'
                                              : name,
                                          textAlign: TextAlign.center,
                                          style: _text(20,
                                              weight: FontWeight.w700)),
                                      const SizedBox(height: 12),
                                      Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                              color: const Color(0xFFD1FAE5),
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          child: Text('Nasabah',
                                              style: _text(13,
                                                  weight: FontWeight.w600,
                                                  color: const Color(
                                                      0xFF047857)))),
                                    ])),
                                const SizedBox(height: 24),
                                Text('Informasi Akun',
                                    style: _text(17, weight: FontWeight.w600)),
                                const SizedBox(height: 12),
                                Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                            color: const Color(0xFFE2E8F0))),
                                    child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.mail_outline,
                                              color: Color(0xFF059669)),
                                          const SizedBox(width: 12),
                                          Expanded(
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                Text('EMAIL',
                                                    style: _text(11,
                                                        weight: FontWeight.w600,
                                                        color: const Color(
                                                            0xFF64748B))),
                                                const SizedBox(height: 4),
                                                Text(
                                                    email.isEmpty
                                                        ? 'Email belum tersedia'
                                                        : email,
                                                    style: _text(15)),
                                              ])),
                                        ])),
                              ],
                            ])))),
          );
        },
      );
}
