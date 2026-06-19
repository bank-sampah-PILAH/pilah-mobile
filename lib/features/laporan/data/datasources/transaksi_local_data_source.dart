import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/laporan/data/models/transaksi_model.dart';

abstract class TransaksiLocalDataSource {
  Future<List<TransaksiGroupModel>> getTransaksi();
  Future<void> addTransaksi(TransaksiModel transaksi);
}

@LazySingleton(as: TransaksiLocalDataSource)
class TransaksiLocalDataSourceImpl implements TransaksiLocalDataSource {
  final List<TransaksiGroupModel> _transaksiList = [
    TransaksiGroupModel(
      header: 'HARI INI',
      transactions: [
        TransaksiModel(
          initials: 'BS',
          avatarColor: AppColors.greenLight,
          textColor: AppColors.greenDark,
          name: 'Budi Santoso',
          subtitle: 'Plastik • 5.2 kg',
          amount: '+Rp 15.600',
          isWaSuccess: true,
          time: '09:45',
          balance: 'Rp 141.100',
          items: [
            ItemSetoranModel(jenis: 'Plastik PET', berat: '5.2 kg', harga: 'Rp 3.000', subtotal: 'Rp 15.600'),
          ],
        ),
        TransaksiModel(
          initials: 'WS',
          avatarColor: AppColors.avatarYellow,
          textColor: AppColors.avatarYellowText,
          name: 'Warung Bu Siti',
          subtitle: 'Logam • 2.1 kg',
          amount: '+Rp 10.500',
          isWaSuccess: false,
          time: '08:30',
          balance: 'Rp 45.500',
          items: [
            ItemSetoranModel(jenis: 'Logam Besi', berat: '2.1 kg', harga: 'Rp 5.000', subtotal: 'Rp 10.500'),
          ],
        ),
      ],
    ),
    TransaksiGroupModel(
      header: 'KEMARIN',
      transactions: [
        TransaksiModel(
          initials: 'KD',
          avatarColor: const Color(0xFFE8EAF6),
          textColor: const Color(0xFF3F51B5),
          name: 'Kantor Desa Mekar',
          subtitle: 'Kertas • 12.0 kg',
          amount: '+Rp 24.000',
          isWaSuccess: true,
          time: null,
          balance: 'Rp 224.000',
          items: [
            ItemSetoranModel(jenis: 'Kertas HVS', berat: '12.0 kg', harga: 'Rp 2.000', subtotal: 'Rp 24.000'),
          ],
        ),
        TransaksiModel(
          initials: 'AY',
          avatarColor: AppColors.greenLight,
          textColor: AppColors.greenDark,
          name: 'Ahmad Yani',
          subtitle: 'Plastik • 3.5 kg',
          amount: '+Rp 10.500',
          isWaSuccess: true,
          time: null,
          balance: 'Rp 50.500',
          items: [
            ItemSetoranModel(jenis: 'Plastik PET', berat: '3.5 kg', harga: 'Rp 3.000', subtotal: 'Rp 10.500'),
          ],
        ),
      ],
    ),
    TransaksiGroupModel(
      header: '3 HARI LALU',
      transactions: [
        TransaksiModel(
          initials: 'CW',
          avatarColor: const Color(0xFFFCE4EC),
          textColor: const Color(0xFFE91E63),
          name: 'Citra Wijaya',
          subtitle: 'Aluminium • 1.8 kg',
          amount: '+Rp 14.400',
          isWaSuccess: false,
          time: null,
          balance: 'Rp 104.400',
          items: [
            ItemSetoranModel(jenis: 'Aluminium', berat: '1.8 kg', harga: 'Rp 8.000', subtotal: 'Rp 14.400'),
          ],
        ),
      ],
    ),
  ];

  @override
  Future<List<TransaksiGroupModel>> getTransaksi() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_transaksiList);
  }

  @override
  Future<void> addTransaksi(TransaksiModel transaksi) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _transaksiList.indexWhere((group) => group.header == 'HARI INI');
    if (index != -1) {
      _transaksiList[index].transactions.insert(0, transaksi);
    } else {
      _transaksiList.insert(0, TransaksiGroupModel(header: 'HARI INI', transactions: [transaksi]));
    }
  }
}
