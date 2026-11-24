import 'package:pilah_mobile/core/client/network_service.dart';
import '../application/role_switch_coordinator.dart';

class RoleSwitchRepository {
  const RoleSwitchRepository(this.network);
  final NetworkService network;

  Future<RoleSwitchSession> request(String role) async {
    throw StateError('Role switching is not implemented');
  }
}
