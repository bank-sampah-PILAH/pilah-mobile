import 'package:flutter/material.dart';

class ItemSetoranEntity {
  final String jenis;
  final String berat;
  final String harga;
  final String subtotal;

  ItemSetoranEntity({
    required this.jenis,
    required this.berat,
    required this.harga,
    required this.subtotal,
  });
}

class TransaksiEntity {
  final String initials;
  final Color avatarColor;
  final Color textColor;
  final String name;
  final String subtitle;
  final String amount;
  final bool isWaSuccess;
  final String? time;
  final String balance;
  final List<ItemSetoranEntity> items;

  TransaksiEntity({
    required this.initials,
    required this.avatarColor,
    required this.textColor,
    required this.name,
    required this.subtitle,
    required this.amount,
    required this.isWaSuccess,
    this.time,
    required this.balance,
    required this.items,
  });
}

class TransaksiGroupEntity {
  final String header;
  final List<TransaksiEntity> transactions;

  TransaksiGroupEntity({
    required this.header,
    required this.transactions,
  });
}
