import 'package:flutter/material.dart';

class NasabahEntity {
  final String id;
  final String idNasabah;
  final String name;
  final String phone;
  final String balance;
  final bool isActive;
  final String address;
  final String initials;
  final Color avatarColor;
  final Color textColor;
  final String jenisKelamin;
  final String tanggalLahir;
  final String tanggalDaftar;

  NasabahEntity({
    required this.id,
    required this.idNasabah,
    required this.name,
    required this.phone,
    required this.balance,
    required this.isActive,
    required this.address,
    required this.initials,
    required this.avatarColor,
    required this.textColor,
    required this.jenisKelamin,
    required this.tanggalLahir,
    this.tanggalDaftar = '',
  });
}

/// Write model for creating/updating a nasabah. Kept separate from
/// [NasabahEntity] so forms don't have to fabricate presentation-only fields
/// (initials, avatar colours, formatted balance) that the backend never stores.
class NasabahRequest {
  final String kode;
  final String nama;
  final String jenisKelamin; // UI label: 'Laki-laki' | 'Perempuan'
  final String tanggalLahir; // display format dd/MM/yyyy
  final String noHp; // may be national digits or +62 prefixed
  final String alamat;

  NasabahRequest({
    required this.kode,
    required this.nama,
    required this.jenisKelamin,
    required this.tanggalLahir,
    required this.noHp,
    required this.alamat,
  });
}

/// Transaction summary returned by the nasabah detail endpoint
/// (`ringkasan_transaksi`).
class NasabahRingkasan {
  final int jumlahTransaksi;
  final String totalKg;
  final String? tanggalTransaksiTerakhir;

  NasabahRingkasan({
    required this.jumlahTransaksi,
    required this.totalKg,
    this.tanggalTransaksiTerakhir,
  });
}
