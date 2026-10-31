import 'package:flutter/material.dart';

class ItemSetoranEntity {
  final String jenis;
  final String berat;
  final String harga;
  final String subtotal;

  /// Raw values kept beside the display strings so the edit form can start
  /// from what was recorded. Empty / zero for rows that only feed a list.
  final String jenisSampahId;
  final num beratKg;
  final int hargaPerKg;

  ItemSetoranEntity({
    required this.jenis,
    required this.berat,
    required this.harga,
    required this.subtotal,
    this.jenisSampahId = '',
    this.beratKg = 0,
    this.hargaPerKg = 0,
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

  /// The raw transaction timestamp, kept alongside the pre-formatted [time]
  /// so callers that need to sort or merge across feeds (e.g. Riwayat
  /// Aktivitas, PIL-282) aren't stuck re-parsing a display string.
  final DateTime? tanggal;

  /// Setoran yang dibatalkan (PIL-428) tetap tampil di riwayat, tetapi tidak
  /// lagi dihitung ke saldo maupun laporan.
  final bool isDibatalkan;

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
    this.tanggal,
    this.isDibatalkan = false,
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
      tanggal: tanggal,
      isDibatalkan: isDibatalkan,
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
  final String idempotencyKey;
  final String? catatan;

  TransaksiRequest(
      {required this.nasabahId,
      required this.items,
      required this.idempotencyKey,
      this.catatan});
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

/// Write model for PATCH /transaksi/{id}. [items] and [catatan] are only sent
/// when they were changed; [alasan] is always required.
class TransaksiEditRequest {
  final String id;
  final List<ItemSetoranRequest>? items;
  final String? catatan;
  final String alasan;

  TransaksiEditRequest({
    required this.id,
    this.items,
    this.catatan,
    required this.alasan,
  });
}

/// A replaced version of a setoran, shown as "Riwayat perubahan" in the detail.
class TransaksiRevisiEntity {
  final int versi;
  final String totalFormatted;
  final String catatan;
  final List<ItemSetoranEntity> items;
  final String alasan;
  final String diubahOlehNama;
  final DateTime? diubahPada;

  TransaksiRevisiEntity({
    required this.versi,
    required this.totalFormatted,
    required this.catatan,
    required this.items,
    required this.alasan,
    required this.diubahOlehNama,
    this.diubahPada,
  });
}

/// Full transaction detail (from GET /transaksi/{id}) for the detail sheet.
class TransaksiDetailEntity {
  final String name;
  final String amountFormatted;
  final String balanceFormatted;
  final String waStatus; // 'sent' | 'failed' | 'pending'
  final List<ItemSetoranEntity> items;
  final String catatan;
  final List<TransaksiRevisiEntity> revisi;

  /// Harga per kg tiap jenis pada tanggal setoran (kunci: id jenis). Edit
  /// menghitung dengan harga ini, bukan harga hari ini.
  final Map<String, int> hargaPadaTanggal;

  /// Waktu setoran dicatat.
  final DateTime? tanggal;

  TransaksiDetailEntity({
    required this.name,
    required this.amountFormatted,
    required this.balanceFormatted,
    required this.waStatus,
    required this.items,
    this.catatan = '',
    this.revisi = const [],
    this.hargaPadaTanggal = const {},
    this.tanggal,
  });
}
