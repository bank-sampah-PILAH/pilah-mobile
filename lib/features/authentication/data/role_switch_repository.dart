import 'package:pilah_mobile/core/client/network_service.dart';
import '../application/role_switch_coordinator.dart';
import 'remote/model/responses/auth_response.dart';
import 'remote/model/mapper/auth_mapper.dart';

class RoleSwitchRepository {
  const RoleSwitchRepository(this.network);
  final NetworkService network;

  Future<RoleSwitchSession> request(String role) async {
    final response =
        await network.post('/api/v1/auth/switch-role', data: {'role': role});
    final payload =
        AuthResponse.fromJson(response.data as Map<String, dynamic>);
    return RoleSwitchSession(
        AuthMapper.mapResponseToDomain(payload), payload.refreshToken);
  }
}
