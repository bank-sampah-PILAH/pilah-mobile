import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/features/harga/data/models/harga_model.dart';

abstract class HargaLocalDataSource {
  Future<List<HargaModel>> getHarga();
  Future<void> addHarga(HargaModel harga);
  Future<void> updateHarga(HargaModel harga);
  Future<void> deactivateHarga(String id);
}

@LazySingleton(as: HargaLocalDataSource)
class HargaLocalDataSourceImpl implements HargaLocalDataSource {
  final List<HargaModel> _jenisSampahList = [
    HargaModel(
      id: 'JS-001',
      name: 'Plastik PET',
      price: 3500,
      priceFormatted: 'Rp 3.500',
      category: 'Plastik',
      subtitle: 'Botol bening, kemasan',
      badgeText: 'Anorganik',
      icon: Icons.recycling,
      iconColor: Colors.green,
      isActive: true,
    ),
    HargaModel(
      id: 'JS-002',
      name: 'Kertas HVS',
      price: 2000,
      priceFormatted: 'Rp 2.000',
      category: 'Kertas',
      subtitle: 'Kertas dokumen, buku',
      badgeText: 'Anorganik',
      icon: Icons.description,
      iconColor: Colors.grey,
      isActive: true,
    ),
    HargaModel(
      id: 'JS-003',
      name: 'Kardus',
      price: 1500,
      priceFormatted: 'Rp 1.500',
      category: 'Kertas',
      subtitle: 'Karton tebal, box',
      badgeText: 'Anorganik',
      icon: Icons.inventory_2,
      iconColor: Colors.brown,
      isActive: true,
    ),
    HargaModel(
      id: 'JS-004',
      name: 'Logam Besi',
      price: 4000,
      priceFormatted: 'Rp 4.000',
      category: 'Logam',
      subtitle: 'Besi tua, kaleng',
      badgeText: 'Anorganik',
      icon: Icons.settings,
      iconColor: Colors.blueGrey,
      isActive: true,
    ),
    HargaModel(
      id: 'JS-005',
      name: 'Aluminium',
      price: 8000,
      priceFormatted: 'Rp 8.000',
      category: 'Logam',
      subtitle: 'Kaleng minuman, foil',
      badgeText: 'Anorganik',
      icon: Icons.ad_units,
      iconColor: Colors.redAccent,
      isActive: true,
    ),
  ];

  @override
  Future<List<HargaModel>> getHarga() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_jenisSampahList);
  }

  @override
  Future<void> addHarga(HargaModel harga) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _jenisSampahList.add(harga);
  }

  @override
  Future<void> updateHarga(HargaModel harga) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _jenisSampahList.indexWhere((h) => h.id == harga.id);
    if (index != -1) {
      _jenisSampahList[index] = harga;
    }
  }

  @override
  Future<void> deactivateHarga(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _jenisSampahList.indexWhere((h) => h.id == id);
    if (index != -1) {
      final old = _jenisSampahList[index];
      _jenisSampahList[index] = HargaModel(
        id: old.id,
        name: old.name,
        price: old.price,
        priceFormatted: old.priceFormatted,
        category: old.category,
        subtitle: old.subtitle,
        badgeText: old.badgeText,
        icon: old.icon,
        iconColor: old.iconColor,
        isActive: false,
      );
    }
  }
}
