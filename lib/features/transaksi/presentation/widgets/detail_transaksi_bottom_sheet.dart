import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_status_badge.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_cubit.dart';

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
  // Emerald Eco System Tokens
  static const Color emeraldPrimary = Color(0xFF006D44);
  static const Color mintTint = Color(0xFFF0FDF4); // or #ecfdf5 as requested
  static const Color errorColor = Color(0xFFDC2626); // red for failed WA

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
    final detail =
        await context.read<TransaksiCubit>().fetchTransaksiDetail(id);
    if (!mounted) return;
    setState(() {
      _detail = detail;
      _isLoadingDetail = false;
      if (detail != null) currentWaStatus = detail.waStatus;
    });
  }

  Future<void> _retryWaNotification() async {
    final id = widget.transactionData['id']?.toString();
    if (id == null || id.isEmpty) return;

    setState(() {
      isLoadingWa = true;
    });

    final result = await context.read<TransaksiCubit>().resendWa(id);
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

  @override
  Widget build(BuildContext context) {
    final String initials = widget.transactionData['initials'] ?? 'NN';
    final Color avatarColor =
        widget.transactionData['avatarColor'] ?? Colors.grey[200]!;
    final Color textColor =
        widget.transactionData['textColor'] ?? Colors.grey[600]!;
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

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detail Transaksi',
                    style: AppTextStyle.headline1.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  CustomStatusBadge(
                    statusText: 'Selesai',
                    backgroundColor: mintTint,
                    textColor: emeraldPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Customer Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB), // surface-container-low
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: avatarColor,
                        borderRadius: BorderRadius.circular(12),
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
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            time,
                            style: AppTextStyle.small.copyWith(
                              color: Colors.grey[500],
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
              Text(
                'RINCIAN SETORAN',
                style: AppTextStyle.extraSmall.copyWith(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
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
                              color: Colors.grey[500],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'BERAT',
                            style: AppTextStyle.extraSmall.copyWith(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'HARGA/KG',
                            style: AppTextStyle.extraSmall.copyWith(
                              color: Colors.grey[500],
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
                              color: Colors.grey[500],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
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
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item['berat'] ?? '',
                                  style: AppTextStyle.small.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  item['harga'] ?? '',
                                  style: AppTextStyle.small.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  item['subtotal'] ?? '',
                                  textAlign: TextAlign.right,
                                  style: AppTextStyle.small.copyWith(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),

                    // Total Row
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Setoran',
                          style: AppTextStyle.small.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          amount,
                          style: AppTextStyle.title1.copyWith(
                            color: emeraldPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saldo Setelah Transaksi',
                          style: AppTextStyle.small.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          balance,
                          style: AppTextStyle.headline1.copyWith(
                            color: emeraldPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // TEMP: the whole "STATUS NOTIFIKASI WA" section is hidden while the
              // notification flow moves from the Twilio webhook to a frontend
              // wa.me redirect. The backend cannot report a "sent" status yet, so
              // this always rendered as "Gagal Kirim". Uncomment to restore it
              // (the leading SizedBox is the spacing below the Saldo box).
              /*
              const SizedBox(height: 24),
              Text(
                'STATUS NOTIFIKASI WA',
                style: AppTextStyle.extraSmall.copyWith(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              _buildWaStatusBox(currentWaStatus, name),
              */
            ],
          ),
        ),
      ),
    );
  }

  // Kept alive (unreferenced) while the WA status section above is disabled.
  // ignore: unused_element
  Widget _buildWaStatusBox(String status, String name) {
    if (status == 'sent') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: emeraldPrimary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: mintTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.wechat,
                  color: emeraldPrimary, size: 24), // Placeholder for WA icon
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Terkirim Sukses',
                    style: AppTextStyle.small.copyWith(
                      color: emeraldPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'ke $name',
                    style: AppTextStyle.extraSmall.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.check, color: emeraldPrimary, size: 20),
          ],
        ),
      );
    } else {
      // Failed Status
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: errorColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2), // very light red
                borderRadius: BorderRadius.circular(12),
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
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            isLoadingWa
                ? Container(
                    width: 32,
                    height: 32,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: emeraldPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _retryWaNotification,
                    icon: const Icon(Icons.refresh,
                        size: 14, color: Colors.white),
                    label: const Text(
                      'Coba Lagi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: emeraldPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
          ],
        ),
      );
    }
  }
}
