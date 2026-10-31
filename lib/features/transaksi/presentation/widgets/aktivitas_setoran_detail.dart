import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/font_weight.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/widgets/app_detail_row.dart';
import 'package:pilah_mobile/design/widgets/app_field_label.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';

class AktivitasSetoranDetail extends StatefulWidget {
  const AktivitasSetoranDetail({
    super.key,
    required this.transactionId,
    required this.loadDetail,
  });

  final String transactionId;
  final Future<TransaksiDetailEntity?> Function(String id) loadDetail;

  @override
  State<AktivitasSetoranDetail> createState() => _AktivitasSetoranDetailState();
}

class _AktivitasSetoranDetailState extends State<AktivitasSetoranDetail> {
  late Future<TransaksiDetailEntity?> _detail;

  @override
  void initState() {
    super.initState();
    _detail = _load();
  }

  Future<TransaksiDetailEntity?> _load() async {
    if (widget.transactionId.isEmpty) return null;
    try {
      return await widget.loadDetail(widget.transactionId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.transactionId.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Text('Rincian setoran tidak tersedia.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: FutureBuilder<TransaksiDetailEntity?>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final detail = snapshot.data;
          if (detail == null) {
            return Row(
              children: [
                const Expanded(
                  child: Text('Rincian setoran tidak dapat dimuat.'),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _detail = _load();
                  }),
                  child: const Text('Coba Lagi'),
                ),
              ],
            );
          }

          return _buildDetails(detail);
        },
      ),
    );
  }

  Widget _buildDetails(TransaksiDetailEntity detail) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppFieldLabel('RINCIAN SETORAN'),
          const SizedBox(height: AppSpacing.sm),
          if (detail.items.isEmpty) const Text('Rincian item tidak tersedia.'),
          for (final item in detail.items)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.jenis,
                          style: AppTextStyle.small.copyWith(
                            color: AppColors.black,
                            fontWeight: AppFontWeight.semibold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        item.subtotal,
                        style: AppTextStyle.small.copyWith(
                          color: AppColors.black,
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  AppDetailRow(label: 'Berat', value: item.berat),
                  AppDetailRow(label: 'Harga/kg', value: item.harga),
                ],
              ),
            ),
          if (detail.balanceFormatted.isNotEmpty)
            AppDetailRow(
              label: 'Saldo setelah transaksi',
              value: detail.balanceFormatted,
            ),
          if (detail.catatan.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const AppFieldLabel('CATATAN'),
            const SizedBox(height: AppSpacing.sm),
            Text(detail.catatan.trim(), style: AppTextStyle.small),
          ],
          if (detail.revisi.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const AppFieldLabel('RIWAYAT PERUBAHAN'),
            const SizedBox(height: AppSpacing.sm),
            for (final revision in detail.revisi.reversed)
              _RevisionCard(revision: revision),
          ],
        ],
      );
}

class _RevisionCard extends StatelessWidget {
  const _RevisionCard({required this.revision});

  final TransaksiRevisiEntity revision;

  @override
  Widget build(BuildContext context) {
    final changedAt = revision.diubahPada;
    final metadata = [
      'Diubah oleh ${revision.diubahOlehNama}',
      if (changedAt != null) _formatDate(changedAt),
    ].join(' • ');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Versi ${revision.versi} (sebelum diubah)',
            style: AppTextStyle.small.copyWith(fontWeight: AppFontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            metadata,
            style: AppTextStyle.extraSmall.copyWith(color: AppColors.grey100),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Alasan: ${revision.alasan}', style: AppTextStyle.small),
          for (final item in revision.items)
            Text(
              '${item.jenis} • ${item.berat} • ${item.subtotal}',
              style: AppTextStyle.small.copyWith(color: AppColors.grey100),
            ),
          if (revision.catatan.isNotEmpty)
            Text(
              'Catatan: ${revision.catatan}',
              style: AppTextStyle.small.copyWith(color: AppColors.grey100),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Total: ${revision.totalFormatted}',
            style: AppTextStyle.small.copyWith(fontWeight: AppFontWeight.bold),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} '
        '${two(value.hour)}.${two(value.minute)}';
  }
}
