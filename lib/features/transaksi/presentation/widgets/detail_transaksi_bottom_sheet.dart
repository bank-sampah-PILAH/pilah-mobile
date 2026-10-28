import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/design/constants/font_size.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/bases/widgets/bottom_sheet_header.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_status_badge.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/design/widgets/app_field_label.dart';
import 'package:pilah_mobile/design/widgets/app_sheet_container.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/transaksi_provider.dart';
import 'package:pilah_mobile/design/constants/colors.dart';

class DetailTransaksiBottomSheet extends StatefulWidget {
  final Map<String, dynamic> transactionData;

  const DetailTransaksiBottomSheet({
    super.key,
    required this.transactionData,
  });

  @override
  State<DetailTransaksiBottomSheet> createState() =>
      _DetailTransaksiBottomSheetState();
}

class _DetailTransaksiBottomSheetState
    extends State<DetailTransaksiBottomSheet> {
  // Local tokens (candidates for AppColors)
  static const Color mintTint = AppColors.greenLight; // or #ecfdf5 as requested
  static const Color errorColor = AppColors.danger; // red for failed WA

  String currentWaStatus = '';
  bool isLoadingWa = false;
  TransaksiDetailEntity? _detail;
  bool _isLoadingDetail = false;

  @override
  void initState() {
    super.initState();
    currentWaStatus = widget.transactionData['waStatus'] ?? 'sent';
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final id = widget.transactionData['id']?.toString();
    if (id == null || id.isEmpty) return;
    setState(() => _isLoadingDetail = true);
    final detail = await ProviderScope.containerOf(context, listen: false)
        .read(transaksiProvider.notifier)
        .fetchTransaksiDetail(id);
    if (!mounted) return;
    setState(() {
      _detail = detail;
      _isLoadingDetail = false;
      if (detail != null) currentWaStatus = detail.waStatus;
    });
  }

  // coverage:ignore-start
  // Unreachable while the WhatsApp status section is hidden in build() (see the
  // TEMP comment there); restore the tests with the section.
  Future<void> _retryWaNotification() async {
    final id = widget.transactionData['id']?.toString();
    if (id == null || id.isEmpty) return;

    setState(() {
      isLoadingWa = true;
    });

    final result = await ProviderScope.containerOf(context, listen: false)
        .read(transaksiProvider.notifier)
        .resendWa(id);
    if (!mounted) return;

    setState(() {
      isLoadingWa = false;
      // Only flip to the success design when the backend confirms the send;
      // on failure we stay on 'failed' so the "Coba Lagi" button remains.
      if (result.success) currentWaStatus = 'sent';
    });

    if (result.success) {
      AppNotification.showSuccess(
        context,
        title: 'Informasi',
        message: 'Pesan WhatsApp berhasil dikirim ulang.',
      );
    } else {
      AppNotification.showError(
        context,
        title: 'Gagal',
        message: result.error ?? 'Terjadi kesalahan',
      );
    }
  }

  // coverage:ignore-end

  @override
  Widget build(BuildContext context) {
    final String initials = widget.transactionData['initials'] ?? 'NN';
    final Color avatarColor =
        widget.transactionData['avatarColor'] ?? AppColors.border;
    final Color textColor =
        widget.transactionData['textColor'] ?? AppColors.grey100;
    final String name = widget.transactionData['name'] ?? 'Unknown';
    final String time = widget.transactionData['time'] ?? 'Hari ini';
    final String amount =
        _detail?.amountFormatted ?? widget.transactionData['amount'] ?? 'Rp 0';
    final String balance = _detail?.balanceFormatted ??
        ((widget.transactionData['balance'] as String?)?.isNotEmpty == true
            ? widget.transactionData['balance']
            : '-');
    final List<Map<String, dynamic>> items = _detail != null
        ? _detail!.items
            .map((i) => {
                  'jenis': i.jenis,
                  'berat': i.berat,
                  'harga': i.harga,
                  'subtotal': i.subtotal,
                })
            .toList()
        : ((widget.transactionData['items'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            []);

    return AppSheetContainer(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BottomSheetHeader(title: 'Detail Transaksi'),
          const SizedBox(height: 8),
          const CustomStatusBadge(
            statusText: 'Selesai',
            backgroundColor: mintTint,
            textColor: AppColors.greenDark,
          ),
          const SizedBox(height: 24),

          // Customer Info Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface, // surface-container-low
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: AppTextStyle.title1.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTextStyle.title1.copyWith(
                          color: AppColors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: AppFontSize.lg,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        time,
                        style: AppTextStyle.small.copyWith(
                          color: AppColors.grey100,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Rincian Setoran Section
          const AppFieldLabel('RINCIAN SETORAN'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              children: [
                // Table Header
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'JENIS',
                        style: AppTextStyle.extraSmall.copyWith(
                          color: AppColors.grey100,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'BERAT',
                        style: AppTextStyle.extraSmall.copyWith(
                          color: AppColors.grey100,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'HARGA/KG',
                        style: AppTextStyle.extraSmall.copyWith(
                          color: AppColors.grey100,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'SUBTOTAL',
                        textAlign: TextAlign.right,
                        style: AppTextStyle.extraSmall.copyWith(
                          color: AppColors.grey100,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),

                // Loading indicator while fetching the item breakdown
                if (_isLoadingDetail && items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Center(
                      child: SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),

                // Table Items
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              item['jenis'] ?? '',
                              style: AppTextStyle.small.copyWith(
                                color: AppColors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              item['berat'] ?? '',
                              style: AppTextStyle.small.copyWith(
                                color: AppColors.grey100,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              item['harga'] ?? '',
                              style: AppTextStyle.small.copyWith(
                                color: AppColors.grey100,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              item['subtotal'] ?? '',
                              textAlign: TextAlign.right,
                              style: AppTextStyle.small.copyWith(
                                color: AppColors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),

                // Total Row
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Setoran',
                      style: AppTextStyle.small.copyWith(
                        color: AppColors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      amount,
                      style: AppTextStyle.title1.copyWith(
                        color: AppColors.greenDark,
                        fontWeight: FontWeight.bold,
                        fontSize: AppFontSize.lg,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Saldo Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: mintTint,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo Setelah Transaksi',
                      style: AppTextStyle.small.copyWith(
                        color: AppColors.grey100,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      balance,
                      style: AppTextStyle.headline1.copyWith(
                        color: AppColors.greenDark,
                        fontWeight: FontWeight.bold,
                        fontSize: AppFontSize.xl,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_detail != null && _detail!.catatan.trim().isNotEmpty) ...[
            const SizedBox(height: 24),
            const AppFieldLabel('CATATAN'),
            const SizedBox(height: 8),
            Text(_detail!.catatan, style: AppTextStyle.small),
          ],
          if (_detail != null && _detail!.revisi.isNotEmpty) ...[
            const SizedBox(height: 24),
            const AppFieldLabel('RIWAYAT PERUBAHAN'),
            const SizedBox(height: 12),
            for (final revisi in _detail!.revisi.reversed)
              _RevisiCard(revisi: revisi),
          ],

          // TEMP: the whole "STATUS NOTIFIKASI WA" section is hidden while the
          // notification flow moves from the Twilio webhook to a frontend
          // wa.me redirect. The backend cannot report a "sent" status yet, so
          // this always rendered as "Gagal Kirim". Uncomment to restore it
          // (the leading SizedBox is the spacing below the Saldo box).
          /*
              const SizedBox(height: 24),
              const AppFieldLabel('STATUS NOTIFIKASI WA'),
              const SizedBox(height: 12),
              _buildWaStatusBox(currentWaStatus, name),
              */
        ],
      ),
    );
  }

  // coverage:ignore-start
  // Only used by the hidden WhatsApp status section (see the TEMP comment above).
  // Kept alive (unreferenced) while the WA status section above is disabled.
  // ignore: unused_element
  Widget _buildWaStatusBox(String status, String name) {
    if (status == 'sent') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.greenDark.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: mintTint,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.wechat,
                  color: AppColors.greenDark,
                  size: 24), // Placeholder for WA icon
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Terkirim Sukses',
                    style: AppTextStyle.small.copyWith(
                      color: AppColors.greenDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'ke $name',
                    style: AppTextStyle.extraSmall.copyWith(
                      color: AppColors.grey100,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.check, color: AppColors.greenDark, size: 20),
          ],
        ),
      );
    } else {
      // Failed Status
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: errorColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.dangerLight, // very light red
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.wechat, color: errorColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gagal Kirim',
                    style: AppTextStyle.small.copyWith(
                      color: errorColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'ke $name',
                    style: AppTextStyle.extraSmall.copyWith(
                      color: AppColors.grey100,
                    ),
                  ),
                ],
              ),
            ),
            AppButton(
              label: 'Coba Lagi',
              icon: Icons.refresh,
              size: AppButtonSize.compact,
              expand: false,
              isLoading: isLoadingWa,
              onPressed: _retryWaNotification,
            ),
          ],
        ),
      );
    }
  }
  // coverage:ignore-end
}

/// Satu versi lama setoran: siapa yang mengubahnya, kapan, mengapa, dan
/// isinya sebelum diubah.
class _RevisiCard extends StatelessWidget {
  const _RevisiCard({required this.revisi});

  final TransaksiRevisiEntity revisi;

  @override
  Widget build(BuildContext context) {
    final waktu = revisi.diubahPada;
    return Container(
      key: ValueKey('revisi-${revisi.versi}'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Versi ${revisi.versi} (sebelum diubah)',
            style: AppTextStyle.small.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            [
              'Diubah oleh ${revisi.diubahOlehNama}',
              if (waktu != null) _formatWaktu(waktu),
            ].join(' • '),
            style: AppTextStyle.extraSmall.copyWith(color: AppColors.grey100),
          ),
          const SizedBox(height: 8),
          Text('Alasan: ${revisi.alasan}', style: AppTextStyle.small),
          const SizedBox(height: 8),
          for (final item in revisi.items)
            Text(
              '${item.jenis} • ${item.berat} • ${item.subtotal}',
              style: AppTextStyle.small.copyWith(color: AppColors.grey100),
            ),
          if (revisi.catatan.isNotEmpty)
            Text('Catatan: ${revisi.catatan}',
                style: AppTextStyle.small.copyWith(color: AppColors.grey100)),
          const SizedBox(height: 8),
          Text(
            'Total: ${revisi.totalFormatted}',
            style: AppTextStyle.small.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static String _formatWaktu(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}.${two(d.minute)}';
  }
}
