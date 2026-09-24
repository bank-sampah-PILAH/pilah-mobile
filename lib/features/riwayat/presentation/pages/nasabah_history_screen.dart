import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/riwayat/presentation/pages/riwayat_nasabah_page.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_membership_content.dart';

/// Re-key history on account or membership changes to discard stale responses.
class NasabahHistoryScreen extends StatelessWidget {
  const NasabahHistoryScreen({super.key, required this.membershipId});
  final String? membershipId;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AuthenticationBloc, AuthenticationStates>(
        builder: (context, state) {
          final auth = state is Authenticated ? state.authEntity : null;
          final member = membershipId;
          return Scaffold(
            backgroundColor: NasabahStyle.background,
            appBar: AppBar(
              title: const Text('Riwayat'),
              leading: IconButton(
                tooltip: 'Kembali ke Beranda',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppLocations.dashboard),
              ),
            ),
            body: SafeArea(
              child: auth?.role != 'nasabah'
                  ? const Center(child: Text('Silakan masuk sebagai nasabah.'))
                  : NasabahMembershipContent(
                      key: ValueKey((auth!.id, auth.email, auth.token, member)),
                      membershipId: member,
                      builder: (id) => RiwayatNasabahPage(
                        key: ValueKey(id),
                        loadPage: (page) =>
                            di<NasabahRepository>().history(id, page: page),
                      ),
                    ),
            ),
          );
        },
      );
}
