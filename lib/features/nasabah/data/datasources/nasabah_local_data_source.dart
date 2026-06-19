import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/nasabah/data/models/nasabah_model.dart';

abstract class NasabahLocalDataSource {
  Future<List<NasabahModel>> getNasabah();
  Future<void> activateNasabah(String id);
  Future<void> deactivateNasabah(String id);
}

@LazySingleton(as: NasabahLocalDataSource)
class NasabahLocalDataSourceImpl implements NasabahLocalDataSource {
  // Move the static list here
  final List<NasabahModel> _nasabahList = [
    NasabahModel(
      id: 'NSB001',
      name: 'Ahmad Ridwan',
      phone: '0812-3456-7890',
      balance: 'Rp 1.250.000',
      isActive: true,
      address: 'Jl. Merdeka No. 123, Jakarta Selatan',
      initials: 'AR',
      avatarColor: AppColors.greenLight,
      textColor: AppColors.greenDark,
    ),
    NasabahModel(
      id: 'NSB002',
      name: 'Budi Santoso',
      phone: '0821-9876-5432',
      balance: 'Rp 850.000',
      isActive: true,
      address: 'Jl. Sudirman Blok B4, Tangerang',
      initials: 'BS',
      avatarColor: Colors.blue[100]!,
      textColor: Colors.blue[800]!,
    ),
    NasabahModel(
      id: 'NSB003',
      name: 'Citra Kirana',
      phone: '0853-1122-3344',
      balance: 'Rp 2.100.000',
      isActive: true,
      address: 'Perumahan Indah Asri Blok C, Depok',
      initials: 'CK',
      avatarColor: Colors.purple[100]!,
      textColor: Colors.purple[800]!,
    ),
    NasabahModel(
      id: 'NSB004',
      name: 'Dewi Putri',
      phone: '0811-2233-4455',
      balance: 'Rp 150.000',
      isActive: false,
      address: 'Jl. Pahlawan No. 45, Bekasi',
      initials: 'DP',
      avatarColor: Colors.orange[100]!,
      textColor: Colors.orange[800]!,
    ),
    NasabahModel(
      id: 'NSB005',
      name: 'Eko Prasetyo',
      phone: '0899-8877-6655',
      balance: 'Rp 450.000',
      isActive: true,
      address: 'Komp. Polri, Ragunan, Jakarta Selatan',
      initials: 'EP',
      avatarColor: Colors.teal[100]!,
      textColor: Colors.teal[800]!,
    ),
    NasabahModel(
      id: 'NSB006',
      name: 'Faisal Akbar',
      phone: '0877-6655-4433',
      balance: 'Rp 3.500.000',
      isActive: false,
      address: 'Jl. Kebon Jeruk, Jakarta Barat',
      initials: 'FA',
      avatarColor: Colors.brown[100]!,
      textColor: Colors.brown[800]!,
    ),
  ];

  @override
  Future<List<NasabahModel>> getNasabah() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_nasabahList);
  }

  @override
  Future<void> activateNasabah(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _nasabahList.indexWhere((n) => n.id == id);
    if (index != -1) {
      final old = _nasabahList[index];
      _nasabahList[index] = NasabahModel(
        id: old.id,
        name: old.name,
        phone: old.phone,
        balance: old.balance,
        isActive: true,
        address: old.address,
        initials: old.initials,
        avatarColor: old.avatarColor,
        textColor: old.textColor,
      );
    }
  }

  @override
  Future<void> deactivateNasabah(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _nasabahList.indexWhere((n) => n.id == id);
    if (index != -1) {
      final old = _nasabahList[index];
      _nasabahList[index] = NasabahModel(
        id: old.id,
        name: old.name,
        phone: old.phone,
        balance: old.balance,
        isActive: false,
        address: old.address,
        initials: old.initials,
        avatarColor: old.avatarColor,
        textColor: old.textColor,
      );
    }
  }
}
