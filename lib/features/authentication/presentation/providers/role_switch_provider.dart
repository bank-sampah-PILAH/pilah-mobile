import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/core/client/network_utils.dart';
import 'package:pilah_mobile/core/database/secure_database.dart';
import 'package:pilah_mobile/services/di.dart';
import '../../application/role_switch_coordinator.dart';
import '../../data/role_session_store.dart';
import '../../data/role_switch_repository.dart';
import '../states/authentication_states.dart';
import 'authentication_provider.dart';

final roleSwitchProvider = ChangeNotifierProvider<RoleSwitchCoordinator>((ref) {
  final repository = RoleSwitchRepository(di<NetworkService>());
  final store = RoleSessionStore(di<SecureDatabase>(), di<NetworkUtils>());
  return RoleSwitchCoordinator(
    readSession: () {
      final state = ref.read(authenticationProvider);
      return state is Authenticated ? state.authEntity : null;
    },
    requestRole: repository.request,
    persistSession: store.save,
    resetRoleState: () => resetRoleScopedState(ref),
    publishSession: (auth) => ref.read(authenticationProvider.notifier).applyRoleSession(auth),
  );
});

void resetRoleScopedState(Ref ref) {}
