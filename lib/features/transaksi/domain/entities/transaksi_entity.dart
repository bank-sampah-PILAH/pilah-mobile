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
  final String id;
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
    this.id = '',
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

  TransaksiEntity copyWith({bool? isWaSuccess}) {
    return TransaksiEntity(
      id: id,
      initials: initials,
      avatarColor: avatarColor,
      textColor: textColor,
      name: name,
      subtitle: subtitle,
      amount: amount,
      isWaSuccess: isWaSuccess ?? this.isWaSuccess,
      time: time,
      balance: balance,
      items: items,
    );
  }
}

class TransaksiGroupEntity {
  final String header;
  final List<TransaksiEntity> transactions;

  TransaksiGroupEntity({
    required this.header,
    required this.transactions,
  });
}

/// Write model for POST /transaksi. `harga_per_kg` is intentionally omitted so
/// the backend fills it from the master jenis sampah price.
class ItemSetoranRequest {
  final String jenisSampahId;
  final double berat;

  ItemSetoranRequest({required this.jenisSampahId, required this.berat});
}

class TransaksiRequest {
  final String nasabahId;
  final List<ItemSetoranRequest> items;
  final String? catatan;

  TransaksiRequest(
      {required this.nasabahId, required this.items, this.catatan});
}

/// Result of creating a transaction, using backend-authoritative totals.
class TransaksiCreated {
  final String id;
  final int totalNilai;
  final int saldoSetelah;
  final int itemCount;

  TransaksiCreated({
    required this.id,
    required this.totalNilai,
    required this.saldoSetelah,
    required this.itemCount,
  });
}

/// Full transaction detail (from GET /transaksi/{id}) for the detail sheet.
class TransaksiDetailEntity {
  final String name;
  final String amountFormatted;
  final String balanceFormatted;
  final String waStatus; // 'sent' | 'failed' | 'pending'
  final List<ItemSetoranEntity> items;

  TransaksiDetailEntity({
    required this.name,
    required this.amountFormatted,
    required this.balanceFormatted,
    required this.waStatus,
    required this.items,
  });
}
