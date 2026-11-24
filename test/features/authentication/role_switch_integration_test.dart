import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/core/client/network_utils.dart';
import 'package:pilah_mobile/core/database/secure_database.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/role_switch_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/profile/domain/entities/profile_entities.dart';
import 'package:pilah_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:pilah_mobile/features/profile/presentation/states/profile_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/aktivitas_selection_provider.dart';
import 'package:pilah_mobile/services/di.dart';
import '../../support/auth_support.dart';
import '../../support/auth_data_support.dart';
import '../../support/profile_support.dart';
import '../../support/stub_api.dart';

void main() {
  tearDown(() => di.reset());
  test('real switch clears role caches before publishing the new session', () async {
    final api = StubApi();
    final stack = AuthStack(api);
    api.on('POST', '/api/v1/auth/switch-role',
      json: authPayload(role: 'nasabah', nextStep: 'nasabah_dashboard'));
    di.registerSingleton<NetworkService>(api.network);
    di.registerSingleton<NetworkUtils>(api.utils);
    di.registerSingleton<SecureDatabase>(stack.database);
    final auth = authNotifierIn(Authenticated(authEntity: const AuthEntity(
      id: 'u1', name: 'Siti', email: '', photoUrl: '', token: 'token-123',
      role: 'pengelola', roles: ['pengelola', 'nasabah'])));
    final profile = TestProfileNotifier.noDataSource();
    final container = ProviderContainer(overrides: [
      authenticationProvider.overrideWith(() => auth),
      profileProvider.overrideWith(() => profile),
    ]);
    addTearDown(container.dispose);
    container.read(profileProvider);
    profile.setStateForTest(const ProfileState(
      status: ProfileStatus.loaded, waTemplate: WaTemplate(template: 'private old template')));
    container.read(aktivitasSelectionProvider.notifier).select('old-transaction');
    var published = false;
    container.listen(authenticationProvider, (_, next) {
      if (next is Authenticated && next.authEntity.role == 'nasabah') {
        published = true;
        expect(container.read(profileProvider).waTemplate, isNull);
        expect(container.read(aktivitasSelectionProvider), isNull);
        expect(api.utils.accessToken, 'access-1');
        expect(api.utils.refreshToken, 'refresh-1');
      }
    });
    await container.read(roleSwitchProvider).switchTo('nasabah');
    expect(published, isTrue);
    expect((container.read(authenticationProvider) as Authenticated).authEntity.role, 'nasabah');
  });
}
