import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/pilih_nasabah_section.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/transaction_summary_section.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/item_setoran_card.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/transaksi_berhasil_bottom_sheet.dart';
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
  String? _errorMessage;

  void _addItem() {
    setState(() {
      setoranItems.add({'jenis': null, 'harga': 0, 'berat': 1});
    });
  }

  String _formatCurrency(int value) {
    String str = value.toString();
    String result = '';
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      result = str[i] + result;
      count++;
      if (count % 3 == 0 && i != 0) {
        result = '.$result';
      }
    }
    return 'Rp $result';
  }

  int get grandTotal {
    return setoranItems.fold(0, (sum, item) {
      final harga = item['harga'] as int? ?? 0;
      final berat = item['berat'] as int? ?? 1;
      return sum + (harga * berat);
    });
  }

  int _parseBalance(String balanceStr) {
    final clean = balanceStr.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
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
                    const SizedBox(height: 12),
                    PilihNasabahSection(
                      selectedCustomer: selectedCustomer,
                      onCustomerSelected: (result) {
                        setState(() {
                          selectedCustomer = result;
                        });
                      },
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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[300]!, width: 1.5),
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
                      )
                    else
                      Column(
                        children: setoranItems.asMap().entries.map((entry) {
                          return ItemSetoranCard(
                            index: entry.key,
                            itemData: entry.value,
                            onChanged: (updated) {
                              setState(() {
                                setoranItems[entry.key] = updated;
                              });
                            },
                            onDelete: () {
                              setState(() {
                                setoranItems.removeAt(entry.key);
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
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              CustomPrimaryButton(
                title: 'Simpan Transaksi',
                icon: Icons.save_outlined,
                onPressed: () {
                  if (selectedCustomer == null || setoranItems.isEmpty || setoranItems.any((item) => item['jenis'] == null)) {
                    setState(() {
                      _errorMessage = 'Data nasabah dan setidaknya 1 item setoran harus diisi lengkap.';
                    });
                    return;
                  }
                  
                  setState(() {
                    _errorMessage = null;
                  });

                  final oldBalanceStr = selectedCustomer!.balance;
              final oldBalance = _parseBalance(oldBalanceStr);
              final newBalance = oldBalance + grandTotal;

              // Extract items
              final formattedItems = setoranItems.map((item) {
                final harga = item['harga'] as int? ?? 0;
                final berat = item['berat'] as int? ?? 1;
                return ItemSetoranEntity(
                  jenis: item['jenis'] ?? 'Tidak Diketahui',
                  berat: '$berat kg',
                  harga: _formatCurrency(harga),
                  subtotal: _formatCurrency(harga * berat),
                );
              }).toList();

              // Create transaction entity
              final newTx = TransaksiEntity(
                initials: selectedCustomer!.initials,
                avatarColor: selectedCustomer!.avatarColor,
                textColor: selectedCustomer!.textColor,
                name: selectedCustomer!.name,
                subtitle: '${formattedItems.first.jenis} • ${formattedItems.first.berat}',
                amount: '+${_formatCurrency(grandTotal)}',
                isWaSuccess: true,
                time: 'Sekarang',
                balance: _formatCurrency(newBalance),
                items: formattedItems,
              );

              context.read<TransaksiCubit>().addTransaksi(newTx);

              // Dismiss keyboard to prevent brief layout overflow errors when bottom sheet appears
              FocusManager.instance.primaryFocus?.unfocus();

              final customerName = selectedCustomer!.name;
              final currentTotalSetoran = grandTotal;
              final currentNewBalance = newBalance;
              final currentItemCount = setoranItems.length;


              showModalBottomSheet(
                context: context,
                isDismissible: true,
                enableDrag: true,
                useRootNavigator: true,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => TransaksiBerhasilBottomSheet(
                  customerName: customerName,
                  totalSetoran: currentTotalSetoran,
                  newBalance: currentNewBalance,
                  itemCount: currentItemCount,
                ),
              ).then((_) {
                if (!mounted) return;
                
                // If the page is already popping (e.g. going to dashboard), don't rebuild
                final route = ModalRoute.of(context);
                if (route != null && !route.isCurrent) return;

                // Clear state
                setState(() {
                  selectedCustomer = null;
                  setoranItems = [];
                  _errorMessage = null;
                  _addItem();
                });
              });
            },
          ),
        ),
      ),
    );
  }
}
