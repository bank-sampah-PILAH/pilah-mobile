import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/api_call.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/pencairan/data/model/mapper/pencairan_mapper.dart';
import 'package:pilah_mobile/features/pencairan/data/model/responses/pencairan_response.dart';
import '../../domain/entities/aktivitas_entity.dart';
import '../../domain/entities/aktivitas_page.dart';
import '../../domain/entities/transaksi_filter.dart';
import '../../domain/repositories/aktivitas_repository.dart';
import '../datasources/transaksi_remote_data_source_impl.dart';

@LazySingleton(as: AktivitasRepository)
class AktivitasRepositoryImpl implements AktivitasRepository {
  AktivitasRepositoryImpl(this.network);
  final NetworkService network;

  @override
  Future<Either<NetworkException, AktivitasPage>> history(
          TransaksiFilter filter) =>
      apiCall<AktivitasPage>(
          func: _fetch(filter), mapper: (value) => value as AktivitasPage);

  Future<AktivitasPage> _fetch(TransaksiFilter filter) async {
    final response = await network.get('/api/v1/aktivitas', queryParams: {
      ...filter.toQueryParams(),
      'page': filter.page,
      'page_size': filter.pageSize ?? 20,
    });
    final json = response.data as Map<String, dynamic>;
    final mapper = TransaksiRemoteDataSourceImpl(network);
    final items = (json['results'] as List).map((raw) {
      final row = raw as Map<String, dynamic>;
      final data = row['data'] as Map<String, dynamic>;
      if (row['tipe'] == 'pencairan') {
        return ActivitasEntity.fromPencairan(
            PencairanMapper.mapResponseToDomain(
                PencairanResponse.fromJson(data)));
      }
      if (row['tipe'] != 'setoran') {
        throw const FormatException('Tipe aktivitas tidak dikenal');
      }
      return ActivitasEntity.fromTransaksi(mapper.mapListItem(data,
          DateTime.tryParse(data['tanggal']?.toString() ?? '')?.toLocal()));
    }).toList();
    return AktivitasPage(items, json['next'] != null);
  }
}
