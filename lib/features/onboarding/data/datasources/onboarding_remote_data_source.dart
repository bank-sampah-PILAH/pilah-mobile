import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/core/constants/endpoints.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';

abstract class OnboardingRemoteDataSource {
  Future<OnboardingResult> completeProfile(CompleteProfileRequest request);
  Future<OnboardingResult> registerBankSampah(RegisterBankSampahRequest request);
}

@LazySingleton(as: OnboardingRemoteDataSource)
class OnboardingRemoteDataSourceImpl implements OnboardingRemoteDataSource {
  final NetworkService networkService;

  OnboardingRemoteDataSourceImpl(this.networkService);

  @override
  Future<OnboardingResult> completeProfile(CompleteProfileRequest request) async {
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
}
