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
      idNasabah: 'NAS-001',
      name: 'Ahmad Ridwan',
      phone: '+6281234567890',
      balance: 'Rp 1.250.000',
      isActive: true,
      address: 'Jl. Merdeka No. 123, Jakarta Selatan',
      initials: 'AR',
      avatarColor: AppColors.greenLight,
      textColor: AppColors.greenDark,
      jenisKelamin: 'Laki-laki',
      tanggalLahir: '12/05/1990',
    ),
    NasabahModel(
      id: 'NSB002',
      idNasabah: 'NAS-002',
      name: 'Budi Santoso',
      phone: '+6282198765432',
      balance: 'Rp 850.000',
      isActive: true,
      address: 'Jl. Sudirman Blok B4, Tangerang',
      initials: 'BS',
      avatarColor: Colors.blue[100]!,
      textColor: Colors.blue[800]!,
      jenisKelamin: 'Laki-laki',
      tanggalLahir: '21/08/1985',
    ),
    NasabahModel(
      id: 'NSB003',
      idNasabah: 'NAS-003',
      name: 'Citra Kirana',
      phone: '+6285311223344',
      balance: 'Rp 2.100.000',
      isActive: true,
      address: 'Perumahan Indah Asri Blok C, Depok',
      initials: 'CK',
      avatarColor: Colors.purple[100]!,
      textColor: Colors.purple[800]!,
      jenisKelamin: 'Perempuan',
      tanggalLahir: '05/11/1992',
    ),
    NasabahModel(
      id: 'NSB004',
      idNasabah: 'NAS-004',
      name: 'Dewi Putri',
      phone: '+6281122334455',
      balance: 'Rp 150.000',
      isActive: false,
      address: 'Jl. Pahlawan No. 45, Bekasi',
      initials: 'DP',
      avatarColor: Colors.orange[100]!,
      textColor: Colors.orange[800]!,
      jenisKelamin: 'Perempuan',
      tanggalLahir: '18/02/1995',
    ),
    NasabahModel(
      id: 'NSB005',
      idNasabah: 'NAS-005',
      name: 'Eko Prasetyo',
      phone: '+6289988776655',
      balance: 'Rp 450.000',
      isActive: true,
      address: 'Komp. Polri, Ragunan, Jakarta Selatan',
      initials: 'EP',
      avatarColor: Colors.teal[100]!,
      textColor: Colors.teal[800]!,
      jenisKelamin: 'Laki-laki',
      tanggalLahir: '30/09/1988',
    ),
    NasabahModel(
      id: 'NSB006',
      idNasabah: 'NAS-006',
      name: 'Faisal Akbar',
      phone: '+6287766554433',
      balance: 'Rp 3.500.000',
      isActive: false,
      address: 'Jl. Kebon Jeruk, Jakarta Barat',
      initials: 'FA',
      avatarColor: Colors.brown[100]!,
      textColor: Colors.brown[800]!,
      jenisKelamin: 'Laki-laki',
      tanggalLahir: '14/07/1991',
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
        idNasabah: old.idNasabah,
        name: old.name,
        phone: old.phone,
        balance: old.balance,
        isActive: true,
        address: old.address,
        initials: old.initials,
        avatarColor: old.avatarColor,
        textColor: old.textColor,
        jenisKelamin: old.jenisKelamin,
        tanggalLahir: old.tanggalLahir,
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
        idNasabah: old.idNasabah,
        name: old.name,
        phone: old.phone,
        balance: old.balance,
        isActive: false,
        address: old.address,
        initials: old.initials,
        avatarColor: old.avatarColor,
        textColor: old.textColor,
        jenisKelamin: old.jenisKelamin,
        tanggalLahir: old.tanggalLahir,
      );
    }
  }
}
