import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/utils/file_downloader.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/design/widgets/nasabah_page_app_bar.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_membership_content.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_resource.dart';
import 'package:pilah_mobile/features/pencairan/presentation/widgets/pencairan_history_tab.dart';
import 'package:pilah_mobile/features/riwayat/presentation/pages/riwayat_nasabah_page.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:share_plus/share_plus.dart';

/// Re-key history on account or membership changes to discard stale responses.
class NasabahHistoryScreen extends StatelessWidget {
  const NasabahHistoryScreen({
    super.key,
    required this.membershipId,
    this.initialPencairan = false,
  });
  final String? membershipId;
  final bool initialPencairan;

  /// Downloads the activity PDF (PIL-315), saves it to Download and offers
  /// sharing — the same flow the XLSX export uses, so both exports behave
  /// identically app-wide.
  Future<void> _exportPdf(BuildContext context, String membershipId) async {
    final loading = AppNotification.showLoading(
      context,
      title: 'Informasi',
      message: 'Menyiapkan laporan PDF...',
    );
    final NasabahExport export;
    try {
      export = await di<NasabahRepository>().exportPdf(membershipId);
    } on NasabahApiException catch (error) {
      await loading.dismiss();
      if (!context.mounted) return;
      AppNotification.showError(
        context,
        title: 'Gagal',
        message: error.message == 'Data gagal dimuat. Periksa koneksi dan coba lagi.'
            ? 'Laporan PDF gagal dibuat. Coba lagi nanti.'
            : error.message,
      );
      return;
    }
    await loading.dismiss();

    final SavedFile saved;
    try {
      saved = await FileDownloader.save(
        filename: export.filename,
        bytes: Uint8List.fromList(export.bytes),
      );
    } catch (e) {
      if (!context.mounted) return;
      AppNotification.showError(
        context,
        title: 'Gagal Menyimpan',
        message: 'Gagal menyimpan laporan: $e',
      );
      return;
    }

    if (!context.mounted) return;
    AppNotification.showSuccess(
      context,
      title: 'Berhasil',
      message: 'Laporan PDF tersimpan di folder ${saved.folder}',
      actionLabel: 'Bagikan',
      onAction: () => SharePlus.instance.share(
        ShareParams(
          files: [XFile(saved.path)],
          text: 'Laporan Riwayat Aktivitas PILAH',
        ),
      ),
    );
  }

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
                                  TextButton.icon(
                                    onPressed: () => _exportPdf(context, id),
                                    style: TextButton.styleFrom(
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.18),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    icon: const Icon(Icons.picture_as_pdf_outlined,
                                        size: 16),
                                    label: Text('Unduh PDF',
                                        style: NasabahStyle.text(
                                          12,
                                          weight: FontWeight.w600,
                                        )),
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
                                    decoration: BoxDecoration(
                                      color: NasabahStyle.line
                                          .withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: TabBar(
                                      dividerColor: Colors.transparent,
                                      indicatorSize: TabBarIndicatorSize.tab,
                                      indicator: BoxDecoration(
                                        color: NasabahStyle.emerald,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      labelColor: Colors.white,
                                      unselectedLabelColor: NasabahStyle.muted,
                                      labelStyle: NasabahStyle.text(14,
                                          weight: FontWeight.w600),
                                      tabs: const [
                                        Tab(text: 'Setoran'),
                                        Tab(text: 'Pencairan'),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: TabBarView(
                                      children: [
                                        RiwayatNasabahPage(
                                          key: ValueKey((
                                            auth.id,
                                            auth.email,
                                            auth.token,
                                            id,
                                          )),
                                          loadPage: (page) =>
                                              di<NasabahRepository>()
                                                  .history(id, page: page),
                                          loadDetail: (transactionId) =>
                                              di<NasabahRepository>()
                                                  .setoranDetail(
                                            id,
                                            transactionId,
                                          ),
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
