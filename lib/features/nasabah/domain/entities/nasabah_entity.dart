import 'package:flutter/material.dart';

class NasabahEntity {
  final String id;
  final String idNasabah;
  final String name;
  final String email;
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

  /// Backend membership status: `pending` | `approved` | `rejected`.
  /// Defaults to approved so legacy payloads keep behaving.
  final String status;

  /// Apakah keanggotaan ini sudah tertaut ke akun nasabah (PIL-206).
  ///
  /// Profil global milik pemilik akun, jadi begitu bernilai `true` pengurus
  /// hanya boleh mengubah nomor anggota dan status keanggotaan; backend
  /// menolak perubahan profil dengan 403 (PIL-223). Default `false` supaya
  /// payload yang belum membawa field ini tidak mengunci nasabah tanpa akun.
  final bool punyaAkun;

  NasabahEntity({
    required this.id,
    required this.idNasabah,
    required this.name,
    this.email = '',
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
    this.status = 'approved',
    this.punyaAkun = false,
  });
}

/// Write model for creating/updating a nasabah. Kept separate from
/// [NasabahEntity] so forms don't have to fabricate presentation-only fields
/// (initials, avatar colours, formatted balance) that the backend never stores.
class NasabahRequest {
  final String kode;
  final String nama;
  final String email;
  final String jenisKelamin; // UI label: 'Laki-laki' | 'Perempuan'
  final String tanggalLahir; // display format dd/MM/yyyy
  final String noHp; // may be national digits or +62 prefixed
  final String alamat;

  NasabahRequest({
    required this.kode,
    required this.nama,
    required this.email,
    required this.jenisKelamin,
    required this.tanggalLahir,
    required this.noHp,
    required this.alamat,
  });
}

/// Profil yang diisikan nasabah sendiri pada akunnya. Terpisah dari catatan
/// bank sampah ([NasabahEntity]), yang boleh disunting pengurus. Nilainya sudah
/// dalam bentuk tampilan (label jenis kelamin, tanggal dd/MM/yyyy).
class NasabahProfilAkun {
  final String nama;
  final String jenisKelamin;
  final String tanggalLahir;
  final String alamat;
  final String noHp;

  const NasabahProfilAkun({
    required this.nama,
    required this.jenisKelamin,
    required this.tanggalLahir,
    required this.alamat,
    required this.noHp,
  });
}

/// Extras returned by the nasabah detail endpoint: the transaction summary
/// (`ringkasan_transaksi`) and, for a membership linked to an account, the
/// nasabah's own profile plus which of its fields differ from this bank
/// sampah's record.
class NasabahRingkasan {
  final int jumlahTransaksi;
  final String totalKg;
  final String? tanggalTransaksiTerakhir;

  /// `null` untuk nasabah tanpa akun.
  final NasabahProfilAkun? profilAkun;

  /// Kunci backend dari field yang berbeda: `nama`, `jenis_kelamin`,
  /// `tanggal_lahir`, `alamat`, `no_hp`.
  final List<String> profilBerbeda;

  NasabahRingkasan({
    required this.jumlahTransaksi,
    required this.totalKg,
    this.tanggalTransaksiTerakhir,
    this.profilAkun,
    this.profilBerbeda = const [],
  });
}

/// Satu halaman daftar nasabah milik satu bank sampah (PIL-214).
///
/// [totalCount] adalah jumlah seluruh nasabah yang cocok dengan penyaring di
/// server, bukan jumlah yang sudah dimuat, sehingga penghitung di layar tetap
/// benar walaupun baru sebagian halaman yang diambil.
class HalamanNasabah {
  final List<NasabahEntity> items;
  final int totalCount;
  final bool hasMore;

  const HalamanNasabah({
    required this.items,
    required this.totalCount,
    required this.hasMore,
  });
}
