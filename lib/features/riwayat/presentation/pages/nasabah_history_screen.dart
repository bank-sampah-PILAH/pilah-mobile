import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/design/widgets/nasabah_page_app_bar.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_membership_content.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_resource.dart';
import 'package:pilah_mobile/features/pencairan/presentation/widgets/pencairan_history_tab.dart';
import 'package:pilah_mobile/features/riwayat/presentation/cubit/riwayat_history_cubit.dart';
import 'package:pilah_mobile/features/riwayat/presentation/pages/riwayat_nasabah_page.dart';
import 'package:pilah_mobile/features/riwayat/presentation/pages/nasabah_pdf_preview_button.dart';
import 'package:pilah_mobile/services/di.dart';

/// Re-key history on account or membership changes to discard stale responses.
class NasabahHistoryScreen extends StatelessWidget {
  const NasabahHistoryScreen({
    super.key,
    required this.membershipId,
    this.initialPencairan = false,
  });
  final String? membershipId;
  final bool initialPencairan;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AuthenticationBloc, AuthenticationStates>(
        builder: (context, state) {
          final auth = state is Authenticated ? state.authEntity : null;
          final member = membershipId;
          return Scaffold(
            backgroundColor: NasabahStyle.background,
            appBar: const NasabahPageAppBar(title: 'Tabungan Saya'),
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
                            child: DefaultTabController(
                              length: 2,
                              initialIndex: initialPencairan ? 1 : 0,
                              child: Column(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.fromLTRB(
                                        16, 12, 16, 8),
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: NasabahStyle.line
                                          .withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TabBar(
                                            dividerColor: Colors.transparent,
                                            indicatorSize:
                                                TabBarIndicatorSize.tab,
                                            indicator: BoxDecoration(
                                              color: NasabahStyle.emerald,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            labelColor: Colors.white,
                                            unselectedLabelColor:
                                                NasabahStyle.muted,
                                            labelStyle: NasabahStyle.text(14,
                                                weight: FontWeight.w600),
                                            tabs: const [
                                              Tab(text: 'Setoran'),
                                              Tab(text: 'Pencairan'),
                                            ],
                                          ),
                                        ),
                                        NasabahPdfPreviewButton(
                                            membershipId: id),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: TabBarView(
                                      children: [
                                        BlocProvider<RiwayatHistoryCubit>(
                                          key: ValueKey((
                                            auth.id,
                                            auth.email,
                                            auth.token,
                                            id,
                                          )),
                                          create: (_) =>
                                              di<RiwayatHistoryCubit>()
                                                ..loadHistory(id, reset: true),
                                          child: const RiwayatNasabahPage(),
                                        ),
                                        const PencairanHistoryTab(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
