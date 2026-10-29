import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/onboarding/data/datasources/onboarding_remote_data_source.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/complete_profile_screen.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/onboarding_support.dart';

class _MockDataSource extends Mock implements OnboardingRemoteDataSource {}

AuthEntity _account(String role, {String? bankSampahStatus}) => AuthEntity(
      id: 'user-1',
      name: 'Sari',
      email: 'sari@example.com',
      photoUrl: '',
      token: 'jwt-$role',
      role: role,
      nextStep: 'complete_profile',
      bankSampahStatus: bankSampahStatus,
    );

/// Lengkapi Profil inside a real router, with the role page as a stand-in, so
/// the link's push has somewhere to go and can be popped back from.
Future<TestAuthenticationNotifier> _pump(
  WidgetTester tester,
  AuthEntity account,
) async {
  final auth = authNotifierIn(Authenticated(authEntity: account));
  final onboarding = buildOnboardingContainer(_MockDataSource());
  addTearDown(onboarding.dispose);
  final router = GoRouter(
    initialLocation: CompleteProfileScreen.route,
    routes: [
      GoRoute(
        path: CompleteProfileScreen.route,
        builder: (_, __) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: '/choose-role',
        builder: (_, __) => const Scaffold(body: Text('ROLE PAGE')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(UncontrolledProviderScope(
    container: onboarding,
    child: withAuthenticationProvider(
      auth,
      MaterialApp.router(routerConfig: router),
    ),
  ));
  await tester.pumpAndSettle();
  return auth;
}

void main() {
  setUp(() {
    if (di.isRegistered<InviteTokenStore>()) {
      di.unregister<InviteTokenStore>();
    }
    di.registerSingleton<InviteTokenStore>(InviteTokenStore());
  });

  testWidgets('names the role being registered and links back to change it',
      (tester) async {
    await _pump(tester, _account('pengelola'));

    expect(find.text('Mendaftar sebagai Pengurus Bank Sampah'), findsOneWidget);

    await tester.tap(find.text('Ganti peran'));
    await tester.pumpAndSettle();

    expect(find.text('ROLE PAGE'), findsOneWidget);
  });

  testWidgets('offers no change once a bank sampah is registered',
      (tester) async {
    await _pump(tester, _account('pengelola', bankSampahStatus: 'rejected'));

    expect(find.text('Ganti peran'), findsNothing);
  });

  testWidgets('offers no change when joining through an invite',
      (tester) async {
    di<InviteTokenStore>().save('invite-token');

    await _pump(tester, _account('pengelola'));

    expect(find.text('Ganti peran'), findsNothing);
  });

  testWidgets('redraws for the new role once the session switches to it',
      (tester) async {
    final auth = await _pump(tester, _account('pengelola'));
    expect(find.text('Data Bank Sampah'), findsOneWidget);

    auth.setStateForTest(Authenticated(authEntity: _account('nasabah')));
    await tester.pumpAndSettle();

    expect(find.text('Mendaftar sebagai Nasabah'), findsOneWidget);
    expect(find.text('Pilih Bank Sampah'), findsOneWidget);
    expect(find.text('Data Bank Sampah'), findsNothing);
  });
}
