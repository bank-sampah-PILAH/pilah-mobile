import 'package:dio/dio.dart';
import 'package:pilah_mobile/core/client/network_service.dart';

class MembershipChoice {
  const MembershipChoice(this.id, this.bankName);
  final String id;
  final String bankName;
}

class NasabahApiException implements Exception {
  const NasabahApiException(this.message, {this.choices = const []});
  final String message;
  final List<MembershipChoice> choices;
}

class NasabahIdentity {
  const NasabahIdentity(this.id, this.name, this.email, this.role,
      {this.noHp = '',
      this.jenisKelamin = '',
      this.tanggalLahir,
      this.alamat = ''});
  factory NasabahIdentity.fromJson(Map<String, dynamic> json) =>
      NasabahIdentity(
        json['id'] as String,
        json['nama'] as String,
        json['email'] as String,
        json['role'] as String,
        noHp: json['no_hp'] as String? ?? '',
        jenisKelamin: json['jenis_kelamin'] as String? ?? '',
        tanggalLahir: json['tanggal_lahir'] == null
            ? null
            : DateTime.parse(json['tanggal_lahir'] as String),
        alamat: json['alamat'] as String? ?? '',
      );
  final String id, name, email, role;
  // Editable by the nasabah via updateProfile; id/email/role never are.
  final String noHp, jenisKelamin, alamat;
  final DateTime? tanggalLahir;
}

class NasabahBalance {
  const NasabahBalance(this.amount, this.updatedAt);
  factory NasabahBalance.fromJson(Map<String, dynamic> json) => NasabahBalance(
        json['total_saldo'] as String,
        json['updated_at'] == null
            ? null
            : DateTime.parse(json['updated_at'] as String),
      );
  // Keep the backend decimal string; do not calculate money with doubles.
  final String amount;
  final DateTime? updatedAt;
}

class NasabahBank {
  const NasabahBank(this.name, this.address, this.city, this.phone);
  factory NasabahBank.fromJson(Map<String, dynamic> json) => NasabahBank(
        json['nama'] as String,
        json['alamat'] as String? ?? '',
        json['kota'] as String? ?? '',
        json['no_hp_pic'] as String? ?? '',
      );
  final String name, address, city, phone;
}

class NasabahActivity {
  const NasabahActivity(this.id, this.date, this.type, this.amount);
  factory NasabahActivity.fromJson(Map<String, dynamic> json) =>
      NasabahActivity(
        json['id'] as String,
        DateTime.parse(json['tanggal'] as String),
        json['tipe'] as String,
        json['total_nilai'] as String,
      );
  final String id, type, amount;
  final DateTime date;
}

class NasabahHome {
  const NasabahHome(this.identity, this.membershipId, this.bank, this.balance,
      this.activities);
  factory NasabahHome.fromJson(Map<String, dynamic> json) => NasabahHome(
        NasabahIdentity.fromJson(json['user'] as Map<String, dynamic>),
        (json['keanggotaan'] as Map<String, dynamic>)['id'] as String,
        NasabahBank.fromJson(json['bank_sampah'] as Map<String, dynamic>),
        NasabahBalance.fromJson(json['saldo'] as Map<String, dynamic>),
        (json['aktivitas_terbaru'] as List)
            .map((v) => NasabahActivity.fromJson(v as Map<String, dynamic>))
            .toList(),
      );
  final NasabahIdentity identity;
  final String membershipId;
  final NasabahBank bank;
  final NasabahBalance balance;
  final List<NasabahActivity> activities;
}

class NasabahHistory {
  const NasabahHistory(this.activities, this.hasNext);
  final List<NasabahActivity> activities;
  final bool hasNext;
}

/// Uses the application's authenticated transport, never the management APIs.
class NasabahRepository {
  NasabahRepository(this.network);
  final NetworkService network;
  static const _base = '/api/v1/nasabah/me';

  Future<Map<String, dynamic>> _get(String path,
      {String? membershipId, int? page}) async {
    try {
      final response = await network.get('$_base/$path', queryParams: {
        if (membershipId != null) 'keanggotaan_id': membershipId,
        if (page != null) 'page': page,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      final errors = data is Map ? data['errors'] : null;
      final choices = errors is Map ? errors['pilihan'] : null;
      if (status == 422 && choices is List && choices.isNotEmpty) {
        throw NasabahApiException('Pilih bank sampah Anda.',
            choices: choices
                .map((v) => MembershipChoice(
                    v['id'] as String, v['bank_sampah_nama'] as String))
                .toList());
      }
      throw NasabahApiException(switch (status) {
        401 => 'Sesi berakhir. Silakan masuk kembali.',
        403 =>
          'Akses belum tersedia. Pastikan akun, keanggotaan, dan bank sampah aktif.',
        404 => 'Data tidak ditemukan. Muat ulang atau pilih keanggotaan lain.',
        422 => 'Pilihan keanggotaan tidak valid. Silakan pilih kembali.',
        _ => 'Data gagal dimuat. Periksa koneksi dan coba lagi.',
      });
    }
  }

  Future<NasabahHome> home({String? membershipId}) async =>
      NasabahHome.fromJson(await _get('beranda', membershipId: membershipId));
  Future<NasabahBalance> balance(String membershipId) async =>
      NasabahBalance.fromJson(await _get('saldo', membershipId: membershipId));
  Future<NasabahBank> bank(String membershipId) async => NasabahBank.fromJson(
      await _get('bank-sampah', membershipId: membershipId));
  Future<NasabahHistory> history(String membershipId, {int page = 1}) async {
    final json = await _get('riwayat', membershipId: membershipId, page: page);
    return NasabahHistory(
        (json['results'] as List)
            .map((v) => NasabahActivity.fromJson(v as Map<String, dynamic>))
            .toList(),
        json['next'] != null);
  }

  Future<NasabahIdentity> profile() async =>
      NasabahIdentity.fromJson(await _get('profil'));

  /// Patches only the fields the nasabah is allowed to edit. `id`, `email`
  /// and `role` are never sent — the backend rejects them anyway.
  Future<NasabahIdentity> updateProfile({
    String? nama,
    String? noHp,
    String? jenisKelamin,
    DateTime? tanggalLahir,
    String? alamat,
  }) async {
    final body = {
      if (nama != null) 'nama': nama,
      if (noHp != null) 'no_hp': noHp,
      if (jenisKelamin != null) 'jenis_kelamin': jenisKelamin,
      if (tanggalLahir != null)
        'tanggal_lahir': '${tanggalLahir.year.toString().padLeft(4, '0')}-'
            '${tanggalLahir.month.toString().padLeft(2, '0')}-'
            '${tanggalLahir.day.toString().padLeft(2, '0')}',
      if (alamat != null) 'alamat': alamat,
    };
    try {
      final response = await network.patch('$_base/profil', data: body);
      return NasabahIdentity.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      throw NasabahApiException(switch (status) {
        400 || 422 => 'Data tidak valid. Periksa isian Anda.',
        401 => 'Sesi berakhir. Silakan masuk kembali.',
        403 =>
          'Akses belum tersedia. Pastikan akun, keanggotaan, dan bank sampah aktif.',
        404 => 'Data tidak ditemukan. Muat ulang atau pilih keanggotaan lain.',
        _ => 'Perubahan gagal disimpan. Periksa koneksi dan coba lagi.',
      });
    } catch (_) {
      // Covers non-Dio failures such as the request timeout wrapper in
      // NetworkService, so a save never crashes the page.
      throw const NasabahApiException(
          'Perubahan gagal disimpan. Periksa koneksi dan coba lagi.');
    }
  }
}
