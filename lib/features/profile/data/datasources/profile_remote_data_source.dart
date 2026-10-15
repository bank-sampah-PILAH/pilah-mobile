import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/core/constants/endpoints.dart';
import 'package:pilah_mobile/core/media/media_url.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/location_service.dart';
import 'package:pilah_mobile/features/profile/domain/entities/profile_entities.dart';

abstract class ProfileRemoteDataSource {
  Future<BankSampahProfile> getBankSampah();

  /// Updates the editable bank sampah fields, optionally replacing the logo
  /// or moving the saved map location (PIL-326).
  ///
  /// [fotoLogoPath] is the absolute path of a freshly picked image. Omitting it
  /// leaves the stored logo alone — the endpoint patches partially, so a key
  /// that is not sent is not touched. Sending an empty one would clear it.
  ///
  /// [lokasi] works the same way but can never clear: a coordinate-less save
  /// sends nothing, and a null pair is not distinctly expressible here, which
  /// is fine because clearing a location is not part of this feature.
  Future<BankSampahProfile> updateBankSampah({
    required String nama,
    required String alamat,
    String? kota,
    required String noHpPic,
    String? fotoLogoPath,
    Uint8List? fotoLogoBytes,
    String? fotoLogoFilename,
    ({double latitude, double longitude})? lokasi,
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
    Uint8List? fotoLogoBytes,
    String? fotoLogoFilename,
    ({double latitude, double longitude})? lokasi,
  }) async {
    final formData = FormData.fromMap({
      'nama': nama,
      'alamat': alamat,
      if (kota != null) 'kota': kota,
      'no_hp_pic': noHpPic,
      // Clamped to six decimals — the model stores Decimal(num_digits=9,
      // places=6), so a longer string would be rejected as "too many digits".
      if (lokasi != null) 'latitude': lokasi.latitude.toStringAsFixed(6),
      if (lokasi != null) 'longitude': lokasi.longitude.toStringAsFixed(6),
      if (fotoLogoBytes != null)
        'foto_logo': MultipartFile.fromBytes(
          fotoLogoBytes,
          filename: fotoLogoFilename ?? 'logo.jpg',
        )
      else if (fotoLogoPath != null && fotoLogoPath.isNotEmpty)
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
      // The shared parser returns null unless both boundaries arrived, so a
      // partially written pair degrades to "no location" instead of crashing
      // somebody's coordinate math.
      lokasi: parseLokasi(json['latitude'], json['longitude']),
      // Which shape `foto_logo` comes back in depends on the backend's
      // storage: with a GCS bucket configured the field serialises to a full
      // https URL, while the local FileSystemStorage yields a bare
      // `/media/...` path, and the view builds its serializer without a
      // request in context so DRF cannot absolutise it. Resolving here means
      // the entity carries one kind of value and no widget has to care which
      // deployment it is talking to.
      fotoLogo: resolveMediaUrl(json['foto_logo']?.toString(),
          () => networkService.environment.baseUrl),
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
