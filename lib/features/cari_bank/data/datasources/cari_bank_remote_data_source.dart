import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/core/constants/endpoints.dart';
import 'package:pilah_mobile/features/cari_bank/domain/entities/cari_bank_entities.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';

/// One page of the directory, per the backend's StandardPagination envelope.
typedef CariBankPage = ({
  List<BankSampahDirectoryEntity> items,
  bool hasMore,
  int totalCount,
});

abstract class CariBankRemoteDataSource {
  Future<CariBankPage> search({String q, String kota, int page});
  Future<BankSampahDetailEntity> detail(String id);
}

@LazySingleton(as: CariBankRemoteDataSource)
class CariBankRemoteDataSourceImpl implements CariBankRemoteDataSource {
  final NetworkService networkService;

  CariBankRemoteDataSourceImpl(this.networkService);

  @override
  Future<CariBankPage> search(
      {String q = '', String kota = '', int page = 1}) async {
    final response = await networkService.get(
      Endpoints.bankSampahDirectory,
      queryParams: {
        'page': '$page',
        if (q.trim().isNotEmpty) 'q': q.trim(),
        if (kota.trim().isNotEmpty) 'kota': kota.trim(),
      },
    );
    final envelope = response.data as Map<String, dynamic>;
    final results = envelope['results'] as List<dynamic>? ?? const [];
    return (
      items: results
          .map((item) =>
              BankSampahDirectoryEntity.fromJson(item as Map<String, dynamic>))
          .toList(),
      hasMore: envelope['next'] != null,
      totalCount: (envelope['count'] as int?) ?? results.length,
    );
  }

  @override
  Future<BankSampahDetailEntity> detail(String id) async {
    final response =
        await networkService.get('${Endpoints.bankSampahDirectory}/$id');
    final json = response.data as Map<String, dynamic>;
    return BankSampahDetailEntity.fromJson(json);
  }
}
