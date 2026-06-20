import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_state.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/detail_transaksi_bottom_sheet.dart';

class TransactionListView extends StatelessWidget {
  const TransactionListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransaksiCubit, TransaksiState>(
      builder: (context, state) {
        if (state is TransaksiLoading || state is TransaksiInitial) {
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: 5,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) => const SkeletonListItem(),
          );
        }

        if (state is TransaksiLoaded) {
          final filteredGroups = state.transaksiList;

          if (filteredGroups.isEmpty) {
            return const EmptyView(
              title: 'Transaksi Tidak Ditemukan',
              subtitle: 'Coba kata kunci atau nama pelanggan lain',
              icon: Icons.search_off,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(bottom: 24),
            itemCount: filteredGroups.length,
            itemBuilder: (context, index) {
              final group = filteredGroups[index];
              final header = group.header;
              final transactions = group.transactions;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(header),
                  ...transactions.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildTransactionCard(
                      context: context,
                      initials: t.initials,
                      avatarColor: t.avatarColor,
                      textColor: t.textColor,
                      name: t.name,
                      subtitle: t.subtitle,
                      amount: t.amount,
                      isWaSuccess: t.isWaSuccess,
                      time: t.time,
                      balance: t.balance,
                      items: t.items,
                    ),
                  )),
                  if (index < filteredGroups.length - 1)
                    const SizedBox(height: 12),
                ],
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: AppTextStyle.extraSmall.copyWith(
          color: Colors.grey[500],
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildTransactionCard({
    required BuildContext context,
    required String initials,
    required Color avatarColor,
    required Color textColor,
    required String name,
    required String subtitle,
    required String amount,
    required bool isWaSuccess,
    required String balance,
    required List<ItemSetoranEntity> items,
    String? time,
  }) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          useRootNavigator: true, 
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => DetailTransaksiBottomSheet(
            transactionData: {
              'initials': initials,
              'avatarColor': avatarColor,
              'textColor': textColor,
              'name': name,
              'time': time ?? 'Hari ini',
              'amount': amount,
              'balance': balance,
              'waStatus': isWaSuccess ? 'sent' : 'failed',
              'items': items.map((i) => {
                'jenis': i.jenis,
                'berat': i.berat,
                'harga': i.harga,
                'subtotal': i.subtotal,
              }).toList(),
            },
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: avatarColor,
              borderRadius: BorderRadius.circular(16),
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
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyle.small.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: AppTextStyle.title1.copyWith(
                  color: AppColors.greenDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isWaSuccess ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isWaSuccess ? Icons.check : Icons.close,
                          color: isWaSuccess ? Colors.green[600] : Colors.red[600],
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'WA',
                          style: TextStyle(
                            color: isWaSuccess ? Colors.green[600] : Colors.red[600],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (time != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: AppTextStyle.extraSmall.copyWith(
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}
