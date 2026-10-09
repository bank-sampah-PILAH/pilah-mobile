import 'package:flutter/material.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_terjadwal.dart';

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
    super.berlakuMulai,
    super.hargaTerjadwal,
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
      berlakuMulai:
          DateTime.tryParse(json['harga_berlaku_mulai'] as String? ?? ''),
      hargaTerjadwal: _parseTerjadwal(json['harga_terjadwal']),
    );
  }

  static HargaTerjadwal? _parseTerjadwal(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final mulai = DateTime.tryParse(json['berlaku_mulai'] as String? ?? '');
    if (mulai == null) return null;
    return HargaTerjadwal(
      harga:
          double.tryParse(json['harga_per_kg']?.toString() ?? '')?.toInt() ?? 0,
      berlakuMulai: mulai,
    );
  }

  /// Field yang dikirim saat menyunting jenis sampah. Harga diganti lewat
  /// `POST /jenis-sampah/{id}/harga` supaya tercatat sebagai versi baru.
  Map<String, dynamic> toUpdateJson() => toJson()..remove('harga_per_kg');

  Map<String, dynamic> toJson() {
    // `id` and `is_active` are read-only on the backend; the record id travels
    // in the URL for updates, and status is toggled via the dedicated /status
    // endpoint. Only send the writable fields.
    return {
      'kode': kodeSampah.trim(),
      'nama_sampah': name.trim(),
      'kategori': category.toLowerCase(),
      'deskripsi': subtitle.trim(),
      'harga_per_kg': price.toString(),
    };
  }
}
