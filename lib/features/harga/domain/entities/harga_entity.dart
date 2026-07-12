import 'package:flutter/material.dart';

class HargaEntity {
  final String id;
  final String kodeSampah;
  final String name;
  final int price;
  final String priceFormatted;
  final String category;
  final String subtitle;
  final String badgeText;
  final IconData icon;
  final Color iconColor;
  final bool isActive;

  HargaEntity({
    required this.id,
    required this.kodeSampah,
    required this.name,
    required this.price,
    required this.priceFormatted,
    required this.category,
    required this.subtitle,
    required this.badgeText,
    required this.icon,
    required this.iconColor,
    required this.isActive,
  });
}
