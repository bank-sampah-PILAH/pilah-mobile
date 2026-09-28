import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_bank_detail.dart';
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
            backgroundColor: NasabahStyle.background,
            appBar: AppBar(
              backgroundColor: NasabahStyle.background,
              surfaceTintColor: Colors.transparent,
              title: Text('Detail Bank Sampah',
                  style: NasabahStyle.text(20, weight: FontWeight.w700)),
            ),
            body: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: NasabahStyle.maxWidth),
                  child: auth?.role != 'nasabah'
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('Silakan masuk sebagai nasabah.',
                              style: NasabahStyle.text(15)),
                        )
                      : NasabahMembershipContent(
                          key: ValueKey((auth!.id, auth.email, auth.token)),
                          builder: (id) => _NasabahBankBody(membershipId: id),
                        ),
                ),
              ),
            ),
          );
        },
      );
}

/// Owns the reload handle across rebuilds so a pull can reach the
/// [NasabahResource] below without the page itself managing a request.
class _NasabahBankBody extends StatefulWidget {
  const _NasabahBankBody({required this.membershipId});
  final String membershipId;
  @override
  State<_NasabahBankBody> createState() => _NasabahBankBodyState();
}

class _NasabahBankBodyState extends State<_NasabahBankBody> {
  Future<void> Function()? _reload;

  @override
  Widget build(BuildContext context) => AppRefreshIndicator(
        onRefresh: () => _reload?.call() ?? Future<void>.value(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            NasabahResource<NasabahBank>(
              key: ValueKey(widget.membershipId),
              load: () => di<NasabahRepository>().bank(widget.membershipId),
              registerReload: (reload) => _reload = reload,
              builder: (_, bank) => NasabahBankDetail(bank: bank),
            ),
          ],
        ),
      );
}
