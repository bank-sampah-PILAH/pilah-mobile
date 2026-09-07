import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/core/constants/endpoints.dart';
import 'package:pilah_mobile/features/profile/domain/entities/profile_entities.dart';

abstract class ProfileRemoteDataSource {
  Future<BankSampahProfile> getBankSampah();

  /// Updates the editable bank sampah fields, optionally replacing the logo.
  ///
  /// [fotoLogoPath] is the absolute path of a freshly picked image. Omitting it
  /// leaves the stored logo alone — the endpoint patches partially, so a key
  /// that is not sent is not touched. Sending an empty one would clear it.
  Future<BankSampahProfile> updateBankSampah({
    required String nama,
    required String alamat,
    String? kota,
    required String noHpPic,
    String? fotoLogoPath,
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

  /// Sent as multipart unconditionally, not only when a logo is attached.
  ///
  /// The endpoint takes JSON too, so a text-only save could keep the old path —
  /// but then the request that carries a file would be the one shape never
  /// exercised by an ordinary save, and the difference would only show up in
  /// production. One encoding for every save keeps the file case on the same
  /// road as the rest.
  @override
  Future<BankSampahProfile> updateBankSampah({
    required String nama,
    required String alamat,
    String? kota,
    required String noHpPic,
    String? fotoLogoPath,
  }) async {
    final formData = FormData.fromMap({
      'nama': nama,
      'alamat': alamat,
      if (kota != null) 'kota': kota,
      'no_hp_pic': noHpPic,
      if (fotoLogoPath != null && fotoLogoPath.isNotEmpty)
        'foto_logo': await MultipartFile.fromFile(
          fotoLogoPath,
          filename: fotoLogoPath.split(RegExp(r'[\\/]')).last,
        ),
    });

    final response = await networkService.putMultipart(
      Endpoints.bankSampahMe,
      formData: formData,
    );
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
      fotoLogo: _absoluteMediaUrl(json['foto_logo']?.toString()),
    );
  }

  /// Turns whatever `foto_logo` came back into something `Image.network` can
  /// fetch, or null when there is no logo.
  ///
  /// Which one it is depends on the backend's storage: with a GCS bucket
  /// configured the field serialises to a full https URL, while the local
  /// FileSystemStorage yields a bare `/media/...` path, and the view builds
  /// its serializer without a request in context so DRF cannot absolutise it.
  /// Resolving here means the entity carries one kind of value and no widget
  /// has to care which deployment it is talking to.
  String? _absoluteMediaUrl(String? raw) {
    final url = raw?.trim();
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;

    final origin = networkService.environment.baseUrl;
    if (origin.isEmpty) return url;
    return '${origin.replaceAll(RegExp(r'/+$'), '')}'
        '/${url.replaceAll(RegExp(r'^/+'), '')}';
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
    await networkService
        .put(Endpoints.waTemplate, data: {'template': template});
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
    final response =
        await networkService.post(Endpoints.teamInvite, data: const {});
    final json = response.data as Map<String, dynamic>;
    return json['invite_url']?.toString() ?? '';
  }
}
