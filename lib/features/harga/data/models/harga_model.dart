import 'package:flutter/material.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';

class HargaModel extends HargaEntity {
  HargaModel({
    required super.id,
    required super.kodeSampah,
    required super.name,
    required super.price,
    required super.priceFormatted,
    required super.category,
    required super.subtitle,
    required super.badgeText,
    required super.icon,
    required super.iconColor,
    required super.isActive,
  });

  factory HargaModel.fromJson(Map<String, dynamic> json) {
    final String priceStr = json['harga_per_kg']?.toString() ?? '0';
    final int price = double.tryParse(priceStr)?.toInt() ?? 0;
    final String category = json['kategori']?.toString() ?? 'dll';
    
    IconData icon = Icons.recycling;
    Color iconColor = Colors.green;
    String badgeText = 'Anorganik';
    
    switch (category.toLowerCase()) {
      case 'kertas':
        icon = Icons.description;
        iconColor = Colors.blue;
        break;
      case 'plastik':
        icon = Icons.local_drink;
        iconColor = Colors.green;
        break;
      case 'logam':
        icon = Icons.hardware;
        iconColor = Colors.grey;
        break;
      case 'kaca':
        icon = Icons.wine_bar;
        iconColor = Colors.teal;
        break;
      case 'organik':
        icon = Icons.eco;
        iconColor = Colors.lightGreen;
        badgeText = 'Organik';
        break;
    }

    return HargaModel(
      id: json['id'] as String? ?? '',
      kodeSampah: json['kode'] as String? ?? '',
      name: json['nama_sampah'] as String? ?? '',
      price: price,
      priceFormatted: 'Rp $price',
      category: category,
      subtitle: json['deskripsi'] as String? ?? '',
      badgeText: badgeText,
      icon: icon,
      iconColor: iconColor,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty && !id.startsWith('JS')) 'id': id,
      'kode': 'JS-${DateTime.now().millisecondsSinceEpoch}', // Required field in backend
      'nama_sampah': name,
      'kategori': category.toLowerCase(),
      'deskripsi': subtitle,
      'harga_per_kg': price.toString(),
      'is_active': isActive,
    };
  }
}
