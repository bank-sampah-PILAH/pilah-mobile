import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:injectable/injectable.dart';

import '../model/responses/pencairan_response.dart';

abstract class PencairanRemoteDataSources {
  Future<PencairanResponse> getSomething();
}

@LazySingleton(as: PencairanRemoteDataSources)
class PencairanRemoteDataSourceImpl implements PencairanRemoteDataSources {
  final NetworkService _networkService;
  const PencairanRemoteDataSourceImpl(this._networkService);

  @override
  Future<PencairanResponse> getSomething() async {
    // TODO: implement via _networkService
    throw UnimplementedError();
  }
}
