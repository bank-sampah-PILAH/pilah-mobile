import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_membership_content.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_resource.dart';
import 'package:pilah_mobile/services/di.dart';

/// Navigation destination reusing the existing public bank-details API.
class NasabahBankPage extends StatelessWidget {
  const NasabahBankPage({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AuthenticationBloc, AuthenticationStates>(
        builder: (context, state) {
          final auth = state is Authenticated ? state.authEntity : null;
          return Scaffold(
            appBar: AppBar(title: const Text('Detail Bank Sampah')),
            body: auth?.role != 'nasabah'
                ? const Center(child: Text('Silakan masuk sebagai nasabah.'))
                : NasabahMembershipContent(
                    key: ValueKey((auth!.id, auth.email, auth.token)),
                    builder: (id) =>
                        ListView(padding: const EdgeInsets.all(16), children: [
                      NasabahResource<NasabahBank>(
                        key: ValueKey(id),
                        load: () => di<NasabahRepository>().bank(id),
                        builder: (_, bank) => Column(children: [
                          Text(bank.name,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Text(bank.address.isEmpty
                              ? 'Alamat belum tersedia'
                              : bank.address),
                          Text(bank.city),
                          Text(bank.phone.isEmpty
                              ? 'Kontak belum tersedia'
                              : bank.phone),
                        ]),
                      ),
                    ]),
                  ),
          );
        },
      );
}
