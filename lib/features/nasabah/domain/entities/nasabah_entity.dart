import 'package:flutter/material.dart';

class NasabahEntity {
  final String id;
  final String name;
  final String phone;
  final String balance;
  final bool isActive;
  final String address;
  final String initials;
  final Color avatarColor;
  final Color textColor;

  NasabahEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.balance,
    required this.isActive,
    required this.address,
    required this.initials,
    required this.avatarColor,
    required this.textColor,
  });
}
