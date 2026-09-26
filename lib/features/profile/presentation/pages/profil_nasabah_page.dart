import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_resource.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/design/widgets/nasabah_card.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';

/// Refreshes read-only identity from the nasabah API without requiring membership.
class ProfilNasabahPage extends StatelessWidget {
  const ProfilNasabahPage({super.key});

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppLocations.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AuthenticationBloc, AuthenticationStates>(
        builder: (context, state) {
          final auth = state is Authenticated ? state.authEntity : null;
          return Scaffold(
            backgroundColor: NasabahStyle.background,
            appBar: AppBar(
              backgroundColor: NasabahStyle.background,
              surfaceTintColor: Colors.transparent,
              title: Text('Profil',
                  style: NasabahStyle.text(20, weight: FontWeight.w700)),
              leading: IconButton(
                  tooltip: 'Kembali ke Beranda',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _back(context)),
            ),
            body: SafeArea(
                child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(
                            maxWidth: NasabahStyle.maxWidth),
                        child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              if (auth?.role != 'nasabah')
                                Text('Silakan masuk untuk melihat profil Anda.',
                                    style: NasabahStyle.text(15))
                              else
                                NasabahResource<NasabahIdentity>(
                                  key: ValueKey((auth!.id, auth.email)),
                                  load: () => di<NasabahRepository>().profile(),
                                  builder: (context, identity) => Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _IdentityCard(name: identity.name.trim()),
                                      const SizedBox(height: 24),
                                      Text('Informasi Akun',
                                          style: NasabahStyle.text(17,
                                              weight: FontWeight.w600)),
                                      const SizedBox(height: 12),
                                      _AccountCard(
                                          email: identity.email.trim()),
                                    ],
                                  ),
                                ),
                            ])))),
          );
        },
      );
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) => NasabahCard(
      padding: 24,
      radius: 24,
      child: Column(children: [
        CircleAvatar(
            radius: 36,
            backgroundColor: NasabahStyle.emeraldLight,
            child: Text(
                name.isEmpty ? 'N' : name.characters.first.toUpperCase(),
                style: NasabahStyle.text(28,
                    weight: FontWeight.w700, color: NasabahStyle.emeraldDark))),
        const SizedBox(height: 16),
        Text(name.isEmpty ? 'Nama belum tersedia' : name,
            textAlign: TextAlign.center,
            style: NasabahStyle.text(20, weight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: NasabahStyle.emeraldLight,
                borderRadius: BorderRadius.circular(8)),
            child: Text('Nasabah',
                style: NasabahStyle.text(13,
                    weight: FontWeight.w600, color: NasabahStyle.emeraldDark))),
      ]));
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.email});
  final String email;
  @override
  Widget build(BuildContext context) => NasabahCard(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.mail_outline, color: NasabahStyle.emerald),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('EMAIL',
              style: NasabahStyle.text(11,
                  weight: FontWeight.w600, color: const Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(email.isEmpty ? 'Email belum tersedia' : email,
              style: NasabahStyle.text(15)),
        ])),
      ]));
}
