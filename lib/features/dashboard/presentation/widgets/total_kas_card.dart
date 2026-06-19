import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_state.dart';

class TotalKasCard extends StatelessWidget {
  const TotalKasCard({super.key});

  int _parseBalance(String balanceStr) {
    final clean = balanceStr.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NasabahCubit, NasabahState>(
      builder: (context, state) {
        int totalSaldo = 0;
        if (state is NasabahLoaded) {
          for (var nasabah in state.nasabahList) {
            if (nasabah.isActive == true) {
              totalSaldo += _parseBalance(nasabah.balance);
            }
          }
        }

        return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.greenDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL KAS BULAN INI',
                style: AppTextStyle.extraSmall.copyWith(
                  color: AppColors.greenLight,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatCurrency(totalSaldo),
                style: AppTextStyle.headline1.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '↑ 18% dari bulan lalu',
                style: AppTextStyle.small.copyWith(
                  color: AppColors.greenLight,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.attach_money,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
        );
      },
    );
  }
}
