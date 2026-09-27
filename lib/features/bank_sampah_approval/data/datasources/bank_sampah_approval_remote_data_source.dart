import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/core/constants/endpoints.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';

abstract class BankSampahApprovalRemoteDataSource {
  Future<List<NasabahMembershipEntity>> getMemberships();

  /// Resubmits a rejected membership for review (PIL-232's appeal action).
  /// Reuses the existing onboarding reapply endpoint: the backend already
  /// rejects this when the membership isn't currently rejected.
  Future<void> appeal(String bankSampahId);
}

@LazySingleton(as: BankSampahApprovalRemoteDataSource)
class BankSampahApprovalRemoteDataSourceImpl
    implements BankSampahApprovalRemoteDataSource {
  final NetworkService networkService;

  BankSampahApprovalRemoteDataSourceImpl(this.networkService);

  @override
  Future<List<NasabahMembershipEntity>> getMemberships() async {
    final response = await networkService.get(Endpoints.nasabahMe);
    final list = response.data as List<dynamic>;
    return list
        .map((item) =>
            NasabahMembershipEntity.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> appeal(String bankSampahId) async {
    await networkService.post(
      Endpoints.onboardingNasabah,
      data: {'bank_sampah_id': bankSampahId},
    );
  }
}
