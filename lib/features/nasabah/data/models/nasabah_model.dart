import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/utils/formatter/weight_formatter.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';

/// Read model: maps the PILAH `NasabahSerializer` JSON to [NasabahEntity].
///
/// Backend keys: id, kode, nama, jenis_kelamin, tanggal_lahir, no_hp, alamat,
/// tanggal_daftar, is_active, total_saldo, created_at.
class NasabahModel extends NasabahEntity {
  NasabahModel({
    required super.id,
    required super.idNasabah,
    required super.name,
    required super.phone,
    required super.balance,
    required super.isActive,
    required super.address,
    required super.initials,
    required super.avatarColor,
    required super.textColor,
    required super.jenisKelamin,
    required super.tanggalLahir,
    required super.tanggalDaftar,
  });

  factory NasabahModel.fromJson(Map<String, dynamic> json) {
    final nama = (json['nama'] as String?)?.trim() ?? '';
    final palette = _avatarPaletteFor(nama);
    return NasabahModel(
      id: json['id']?.toString() ?? '',
      idNasabah: json['kode']?.toString() ?? '',
      name: nama,
      phone: json['no_hp']?.toString() ?? '',
      balance: formatRupiah(json['total_saldo']),
      isActive: json['is_active'] as bool? ?? true,
      address: json['alamat']?.toString() ?? '',
      initials: initialsOf(nama),
      avatarColor: palette.$1,
      textColor: palette.$2,
      jenisKelamin: genderLabel(json['jenis_kelamin']?.toString()),
      tanggalLahir: isoToDisplay(json['tanggal_lahir']?.toString()),
      tanggalDaftar: isoToDisplay(json['tanggal_daftar']?.toString()),
    );
  }

  /// Builds the request body for POST/PUT `/nasabah` from a [NasabahRequest].
  static Map<String, dynamic> toPayload(NasabahRequest request) {
    return {
      'kode': request.kode.trim(),
      'nama': request.nama.trim(),
      'jenis_kelamin': genderValue(request.jenisKelamin),
      'tanggal_lahir': displayToIso(request.tanggalLahir),
      'no_hp': request.noHp.trim(),
      'alamat': request.alamat.trim(),
    };
  }

  // ---- formatting helpers -------------------------------------------------

  static String formatRupiah(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? '') ?? 0;
    final digits = amount.round().abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    final sign = amount < 0 ? '-' : '';
    return 'Rp $sign${buffer.toString()}';
  }

  static String initialsOf(String name) {
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'NN';
    return parts
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
  }

  /// Maps the backend gender value to the UI label used by the dropdowns.
  static String genderLabel(String? value) {
    switch (value) {
      case 'perempuan':
        return 'Perempuan';
      case 'laki-laki':
        return 'Laki-laki';
      default:
        return '';
    }
  }

  /// Maps the UI gender label back to the backend value.
  static String genderValue(String label) {
    return label.toLowerCase() == 'perempuan' ? 'perempuan' : 'laki-laki';
  }

  /// `YYYY-MM-DD` (or ISO datetime) -> `dd/MM/yyyy` for display.
  static String isoToDisplay(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final datePart = iso.split('T').first;
    final parts = datePart.split('-');
    if (parts.length != 3) return iso;
    final year = parts[0];
    final month = parts[1].padLeft(2, '0');
    final day = parts[2].padLeft(2, '0');
    return '$day/$month/$year';
  }

  /// `dd/MM/yyyy` -> `YYYY-MM-DD` for the API. Falls back to the raw value if
  /// the input isn't in the expected shape (e.g. already ISO).
  static String displayToIso(String display) {
    final trimmed = display.trim();
    final parts = trimmed.split('/');
    if (parts.length != 3) return trimmed;
    final day = parts[0].padLeft(2, '0');
    final month = parts[1].padLeft(2, '0');
    final year = parts[2];
    return '$year-$month-$day';
  }

  static (Color, Color) _avatarPaletteFor(String name) {
    if (name.isEmpty) return _avatarPalette.first;
    return _avatarPalette[name.hashCode.abs() % _avatarPalette.length];
  }

  static const List<(Color, Color)> _avatarPalette = [
    (Color(0xFFEAF5EC), Color(0xFF2F6B45)), // green
    (Color(0xFFDBEAFE), Color(0xFF1E40AF)), // blue
    (Color(0xFFF3E8FF), Color(0xFF6B21A8)), // purple
    (Color(0xFFFFF8D6), Color(0xFFD4A017)), // yellow
    (Color(0xFFFFEDD5), Color(0xFF9A3412)), // orange
    (Color(0xFFCCFBF1), Color(0xFF0F766E)), // teal
  ];
}

extension NasabahRingkasanMapper on NasabahRingkasan {
  static NasabahRingkasan fromJson(Map<String, dynamic> json) {
    return NasabahRingkasan(
      jumlahTransaksi: (json['jumlah_transaksi'] as num?)?.toInt() ?? 0,
      totalKg: WeightFormatter.formatKg(json['total_kg']),
      tanggalTransaksiTerakhir:
          NasabahModel.isoToDisplay(json['tanggal_transaksi_terakhir']?.toString()),
    );
  }
}
