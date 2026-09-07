import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/core/constants/endpoints.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';

abstract class OnboardingRemoteDataSource {
  Future<OnboardingResult> completeProfile(CompleteProfileRequest request);
  Future<OnboardingResult> registerBankSampah(
      RegisterBankSampahRequest request);
  Future<OnboardingResult> acceptInvite(String token);
}

@LazySingleton(as: OnboardingRemoteDataSource)
class OnboardingRemoteDataSourceImpl implements OnboardingRemoteDataSource {
  final NetworkService networkService;

  OnboardingRemoteDataSourceImpl(this.networkService);

  @override
  Future<OnboardingResult> completeProfile(
      CompleteProfileRequest request) async {
    final response = await networkService.put(
      Endpoints.onboardingProfile,
      data: request.toJson(),
    );
    final json = response.data as Map<String, dynamic>;
    return OnboardingResult(nextStep: json['next_step']?.toString());
  }

  @override
  Future<OnboardingResult> registerBankSampah(
      RegisterBankSampahRequest request) async {
    final fileName = request.fotoKegiatanPath.split(RegExp(r'[\\/]')).last;
    final formData = FormData.fromMap({
      'nama': request.nama,
      'alamat': request.alamat,
      if (request.kota != null && request.kota!.trim().isNotEmpty)
        'kota': request.kota!.trim(),
      'no_hp_pic': request.noHpPic,
      'foto_kegiatan': await MultipartFile.fromFile(
        request.fotoKegiatanPath,
        filename: fileName,
      ),
    });

    final response = await networkService.postMultipart(
      Endpoints.onboardingBankSampah,
      formData: formData,
    );
    final json = response.data as Map<String, dynamic>;
    return OnboardingResult(nextStep: json['next_step']?.toString());
  }

  @override
  Future<OnboardingResult> acceptInvite(String token) async {
    // Returns the joined bank sampah alongside `next_step`.
    //
    // `outcome`/`message` are read as well because not every refusal is an
    // error status: an account that already belongs to *this* invite's bank
    // sampah comes back as 200 with `{"outcome": "already_member", "message":
    // "Anda sudah terdaftar pada bank sampah ini"}`, which looks like a
    // successful join to anything that only keeps `next_step`. A stale/expired
    // token, or an account already on a *different* bank sampah, still comes
    // back as 400 {"error": ...}.
    final response = await networkService.post(
      Endpoints.invitesAccept,
      data: {'token': token},
    );
    final json = response.data as Map<String, dynamic>;
    return OnboardingResult(
      nextStep: json['next_step']?.toString(),
      outcome: json['outcome']?.toString(),
      message: (json['message'] ?? json['detail'])?.toString(),
      // The body is the joined bank sampah serialised, so `nama` is the bank's.
      // Only safe to read here: the profile endpoint returns a `nama` too, and
      // that one is the user's.
      bankSampahNama: (json['nama'] ?? json['bank_sampah_nama'])?.toString(),
    );
  }
}
