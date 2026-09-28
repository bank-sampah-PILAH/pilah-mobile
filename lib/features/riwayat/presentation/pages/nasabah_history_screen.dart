import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_membership_content.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_resource.dart';
import 'package:pilah_mobile/features/riwayat/presentation/pages/riwayat_nasabah_page.dart';
import 'package:pilah_mobile/services/di.dart';

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
              backgroundColor: NasabahStyle.background,
              foregroundColor: NasabahStyle.ink,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'Tabungan Saya',
                style: NasabahStyle.text(18, weight: FontWeight.w600),
              ),
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
                      builder: (id) => Column(
                        children: [
                          NasabahResource<NasabahBalance>(
                            key: ValueKey((
                              'balance',
                              auth.id,
                              auth.email,
                              auth.token,
                              id,
                            )),
                            load: () => di<NasabahRepository>().balance(id),
                            builder: (_, balance) => Container(
                              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: NasabahStyle.emerald,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'SALDO TABUNGAN',
                                          style: NasabahStyle.text(
                                            11,
                                            weight: FontWeight.w600,
                                            color: NasabahStyle.emeraldLight,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          nasabahRupiah(balance.amount),
                                          style: NasabahStyle.text(
                                            24,
                                            weight: FontWeight.w700,
                                            color: Colors.white,
                                            height: 1.25,
                                          ),
                                        ),
                                        Text(
                                          balance.updatedAt == null
                                              ? 'Saldo saat ini'
                                              : 'Diperbarui ${nasabahDate(balance.updatedAt!)}',
                                          style: NasabahStyle.text(
                                            12,
                                            color: NasabahStyle.emeraldLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.account_balance_wallet_outlined,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: RiwayatNasabahPage(
                              key: ValueKey((
                                auth.id,
                                auth.email,
                                auth.token,
                                id,
                              )),
                              loadPage: (page) => di<NasabahRepository>()
                                  .history(id, page: page),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          );
        },
      );
}
