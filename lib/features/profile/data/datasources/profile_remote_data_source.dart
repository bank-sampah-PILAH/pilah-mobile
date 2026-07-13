import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/core/constants/endpoints.dart';
import 'package:pilah_mobile/features/profile/domain/entities/profile_entities.dart';

abstract class ProfileRemoteDataSource {
  Future<BankSampahProfile> getBankSampah();
  Future<BankSampahProfile> updateBankSampah({
    required String nama,
    required String alamat,
    String? kota,
    required String noHpPic,
  });
  Future<WaTemplate> getWaTemplate();
  Future<void> updateWaTemplate(String template);
  Future<List<TeamMember>> getTeam();
  Future<String> generateInviteUrl();
}

@LazySingleton(as: ProfileRemoteDataSource)
class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final NetworkService networkService;

  ProfileRemoteDataSourceImpl(this.networkService);

  @override
  Future<BankSampahProfile> getBankSampah() async {
    final response = await networkService.get(Endpoints.bankSampahMe);
    return _mapBankSampah(response.data as Map<String, dynamic>);
  }

  @override
  Future<BankSampahProfile> updateBankSampah({
    required String nama,
    required String alamat,
    String? kota,
    required String noHpPic,
  }) async {
    final response = await networkService.put(Endpoints.bankSampahMe, data: {
      'nama': nama,
      'alamat': alamat,
      if (kota != null) 'kota': kota,
      'no_hp_pic': noHpPic,
    });
    return _mapBankSampah(response.data as Map<String, dynamic>);
  }

  BankSampahProfile _mapBankSampah(Map<String, dynamic> json) {
    return BankSampahProfile(
      id: json['id']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      alamat: json['alamat']?.toString() ?? '',
      kota: json['kota']?.toString() ?? '',
      noHpPic: json['no_hp_pic']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }

  @override
  Future<WaTemplate> getWaTemplate() async {
    final response = await networkService.get(Endpoints.waTemplate);
    final json = response.data as Map<String, dynamic>;
    return WaTemplate(
      template: json['template']?.toString() ?? '',
      preview: json['preview_contoh']?.toString(),
      variables: (json['variabel_tersedia'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  @override
  Future<void> updateWaTemplate(String template) async {
    await networkService.put(Endpoints.waTemplate, data: {'template': template});
  }

  @override
  Future<List<TeamMember>> getTeam() async {
    final response = await networkService.get(Endpoints.team);
    final data = response.data;
    final List<dynamic> members = data is Map<String, dynamic>
        ? (data['members'] as List? ?? [])
        : (data as List? ?? []);
    return members.map((raw) {
      final json = raw as Map<String, dynamic>;
      return TeamMember(
        id: json['id']?.toString() ?? '',
        nama: json['nama']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        isPrimary: json['is_primary_pengelola'] == true,
        isCurrentUser: json['is_current_user'] == true,
      );
    }).toList();
  }

  @override
  Future<String> generateInviteUrl() async {
    final response = await networkService.post(Endpoints.teamInvite, data: const {});
    final json = response.data as Map<String, dynamic>;
    return json['invite_url']?.toString() ?? '';
  }
}
