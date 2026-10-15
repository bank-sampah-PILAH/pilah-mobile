import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/core/constants/endpoints.dart';

class PublicConfigRemoteDataSource {
  final NetworkService _networkService;

  const PublicConfigRemoteDataSource(this._networkService);

  Future<bool> reviewerLoginEnabled() async {
    final response = await _networkService.get(
      Endpoints.publicConfig,
      headers: {'Cache-Control': 'no-store'},
    );
    final config = response.data;
    if (config is! Map<String, dynamic> ||
        config.length != 1 ||
        config['demoLoginEnabled'] is! bool) {
      throw const FormatException('Invalid public configuration');
    }
    return config['demoLoginEnabled'] as bool;
  }
}
