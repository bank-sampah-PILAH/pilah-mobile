import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/pilih_nasabah_section.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/transaksi_berhasil_bottom_sheet.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/transaction_summary_section.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/item_setoran_card.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_primary_button.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_outlined_button.dart';

class TransaksiBaruPage extends StatefulWidget {
  const TransaksiBaruPage({super.key});

  static const route = '/transaksi-baru';

  @override
  State<TransaksiBaruPage> createState() => _TransaksiBaruPageState();
}

class _TransaksiBaruPageState extends State<TransaksiBaruPage> {
  NasabahEntity? selectedCustomer;
  List<Map<String, dynamic>> setoranItems = [];
  bool _hasSubmitted = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // The jenis-sampah dropdown options come from HargaCubit, which is otherwise
    // only loaded when the price-list (Harga) page is visited. Load here so the
    // dropdown has options even when arriving straight from the dashboard.
    context.read<HargaCubit>().loadHarga();
  }

  void _addItem() {
    setState(() {
      setoranItems.add({'jenis': null, 'jenis_sampah_id': null, 'harga': 0, 'berat': 1.0});
    });
  }

  Future<void> _handleSubmit() async {
    setState(() => _hasSubmitted = true);

    if (selectedCustomer == null ||
        setoranItems.isEmpty ||
        setoranItems.any((item) => item['jenis_sampah_id'] == null)) {
      return;
    }

    final request = TransaksiRequest(
      nasabahId: selectedCustomer!.id,
      items: setoranItems
          .map((item) => ItemSetoranRequest(
                jenisSampahId: item['jenis_sampah_id'] as String,
                berat: (item['berat'] as num?)?.toDouble() ?? 0,
              ))
          .toList(),
    );

    final cubit = context.read<TransaksiCubit>();
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() => _isSaving = true);
    final result = await cubit.addTransaksi(request);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.error != null) {
      AppNotification.showError(
        context,
        title: 'Gagal Menyimpan',
        message: result.error!.displayMessage,
      );
      return;
    }

    // Refresh dashboard metrics so Total Kas / Sampah / Transaksi reflect this
    // new setoran (the dashboard tab stays alive and won't re-init on its own).
    context.read<DashboardCubit>().loadStats();
    context.read<NasabahCubit>().loadNasabah();

    final created = result.created!;
    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (sheetContext) => TransaksiBerhasilBottomSheet(
        customerName: selectedCustomer!.name,
        totalSetoran: created.totalNilai,
        newBalance: created.saldoSetelah,
        itemCount: created.itemCount,
        onKirimWaSelesai: () async {
          final waResult = await cubit.resendWa(created.id);
          if (!mounted) return;
          Navigator.of(sheetContext).pop();
          context.pop();
          if (waResult.success) {
            AppNotification.showSuccess(
              context,
              title: 'Berhasil',
              message: 'Transaksi disimpan & notifikasi WhatsApp terkirim.',
            );
          } else {
            AppNotification.showError(
              context,
              title: 'Peringatan',
              message:
                  'Transaksi disimpan, namun gagal mengirim WhatsApp otomatis. Silakan coba lagi di detail transaksi.',
            );
          }
        },
      ),
    );
  }

  int get grandTotal {
    return setoranItems.fold(0, (sum, item) {
      final harga = item['harga'] as int? ?? 0;
      final berat = item['berat'] as num? ?? 1.0;
      return sum + (harga * berat).round();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.arrow_back, color: Colors.grey[800], size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Transaksi Baru',
                    style: AppTextStyle.headline1.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: PILIH NASABAH
                    Text(
                      'PILIH NASABAH',
                      style: AppTextStyle.extraSmall.copyWith(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    PilihNasabahSection(
                      selectedCustomer: selectedCustomer,
                      onCustomerSelected: (customer) {
                        setState(() {
                          selectedCustomer = customer;
                        });
                      },
                      hasError: _hasSubmitted && selectedCustomer == null,
                      errorText: 'Nasabah harus dipilih',
                    ),
                    const SizedBox(height: 24),

                    // Section 2: DAFTAR SETORAN
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'DAFTAR SETORAN',
                          style: AppTextStyle.extraSmall.copyWith(
                            color: Colors.grey[500],
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          '${setoranItems.length} item',
                          style: AppTextStyle.small.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Items or Empty State
                    if (setoranItems.isEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: (_hasSubmitted && setoranItems.isEmpty) ? const Color(0xFFDC2626) : Colors.grey[300]!, 
                                width: 1.5
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(Icons.add, color: Colors.grey[400], size: 24),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Belum Ada Item Setoran',
                                  style: AppTextStyle.title1.copyWith(
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap tombol di bawah untuk menambah item.',
                                  style: AppTextStyle.small.copyWith(
                                    color: Colors.grey[400],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          if (_hasSubmitted && setoranItems.isEmpty) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                'Daftar setoran tidak boleh kosong',
                                style: AppTextStyle.small.copyWith(
                                  color: const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ],
                      )
                    else
                      Column(
                        children: List.generate(setoranItems.length, (index) {
                          return ItemSetoranCard(
                            index: index,
                            itemData: setoranItems[index],
                            hasError: _hasSubmitted && setoranItems[index]['jenis'] == null,
                            errorText: 'Pilih jenis sampah',
                            onChanged: (updatedItem) {
                              setState(() {
                                setoranItems[index] = updatedItem;
                              });
                            },
                            onDelete: () {
                              setState(() {
                                setoranItems.removeAt(index);
                              });
                              AppNotification.showSuccess(
                                context,
                                title: 'Item Dihapus',
                                message: 'Item setoran berhasil dihapus.',
                              );
                            },
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 16),

                    // Add Item Button
                    CustomOutlinedButton(
                      title: 'Tambah Item Setoran',
                      icon: Icons.add,
                      borderColor: Colors.grey[300]!,
                      textColor: AppColors.greenDark,
                      onPressed: _addItem,
                    ),
                    const SizedBox(height: 24),

                    TransactionSummarySection(grandTotal: grandTotal),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPrimaryButton(
                title: _isSaving ? 'Menyimpan...' : 'Simpan Transaksi',
                icon: Icons.save_outlined,
                onPressed: _isSaving ? null : _handleSubmit,
              ),
        ],
      ),
    ),
  ),
);
  }
}
