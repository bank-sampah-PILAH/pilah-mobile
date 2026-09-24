import 'dart:async';

import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/router/app_router_config.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:pilah_mobile/features/profile/presentation/cubit/profile_state.dart';
import 'package:pilah_mobile/services/di.dart';

class _Auth extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

class _Profile extends MockCubit<ProfileState> implements ProfileCubit {}

// Proposed first slice for PIL-226, not an external ticket specification.
// Editing personal details, membership APIs, and logout are separate slices.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final router = AppRouterConfig.getRouter();
  tearDownAll(router.dispose);
  late _Profile profile;

  Future<void> openProfile(
    WidgetTester tester, {
    String name = 'Siti Aminah',
    String email = 'siti@example.test',
    String route = '/profile',
    String? apiName,
    bool membershipActive = true,
    Stream<AuthenticationStates>? states,
  }) async {
    final auth = _Auth();
    profile = _Profile();
    final invites = InviteTokenStore();
    di.registerSingleton<InviteTokenStore>(invites);
    di.registerSingleton<NasabahRepository>(
        PreviewNasabahRepository(name: apiName ?? name, email: email));
    whenListen(auth, states ?? const Stream<AuthenticationStates>.empty(),
        initialState: Authenticated(
            authEntity: AuthEntity(
          id: 'nasabah-226',
          name: name,
          email: email,
          photoUrl: '',
          token: 'test-token',
          role: 'nasabah',
          nextStep: 'dashboard',
          bankSampahStatus: membershipActive ? 'active' : 'pending',
          bankSampahNama: 'Bank Sampah Melati',
        )));
    whenListen(profile, const Stream<ProfileState>.empty(),
        initialState: const ProfileState(status: ProfileStatus.loaded));
    when(() => profile.load(silent: true)).thenAnswer((_) async {});
    addTearDown(() async {
      await auth.close();
      await profile.close();
      await di.unregister<InviteTokenStore>();
      await di.unregister<NasabahRepository>();
      invites.dispose();
    });
    router.go(route);
    await tester.pumpWidget(MultiBlocProvider(providers: [
      BlocProvider<AuthenticationBloc>.value(value: auth),
      BlocProvider<ProfileCubit>.value(value: profile),
    ], child: MaterialApp.router(routerConfig: router)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  group('PIL-226 profil nasabah — proposed RED slice', () {
    testWidgets(
        'logout clears customer identity without loading staff settings',
        (tester) async {
      final states = StreamController<AuthenticationStates>();
      addTearDown(states.close);
      await openProfile(tester, states: states.stream);
      expect(find.text('siti@example.test'), findsOneWidget);
      states.add(Unauthenticated());
      await tester.pumpAndSettle();
      expect(find.text('siti@example.test'), findsNothing);
      expect(find.text('Silakan masuk untuk melihat profil Anda.'),
          findsOneWidget);
      verifyNever(() => profile.load(silent: true));
    });
    testWidgets('akses Profil dari Beranda membuka profil akun',
        (tester) async {
      await openProfile(tester, route: '/dashboard');
      final entry = find.byTooltip('Profil');
      expect(entry, findsOneWidget,
          reason:
              'Avatar perlu menjadi akses Profil yang berlabel dan dapat diketuk');
      await tester.tap(entry);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/profile');
      expect(find.text('siti@example.test'), findsOneWidget);
    });

    for (final user in [
      (name: 'Siti Aminah', email: 'siti@example.test'),
      (name: 'Budi Santoso', email: 'budi@example.test'),
    ]) {
      testWidgets('profil menampilkan identitas sesi ${user.name}',
          (tester) async {
        await openProfile(tester, name: user.name, email: user.email);
        expect(find.text(user.name), findsOneWidget);
        expect(find.text(user.email), findsOneWidget);
        expect(
            find.text(user.email == 'siti@example.test'
                ? 'budi@example.test'
                : 'siti@example.test'),
            findsNothing);
      });
    }

    testWidgets('profile refreshes server identity without active membership',
        (tester) async {
      await openProfile(tester,
          name: 'Old session name',
          apiName: 'Updated API name',
          membershipActive: false);
      expect(find.text('Updated API name'), findsOneWidget);
      expect(find.text('Old session name'), findsNothing);
    });

    testWidgets('role nasabah tidak dilabeli Pengelola', (tester) async {
      await openProfile(tester);
      expect(find.text('Nasabah'), findsOneWidget);
      expect(find.text('Pengelola'), findsNothing);
    });

    testWidgets('profil nasabah tidak menawarkan pengaturan bank dan tim',
        (tester) async {
      await openProfile(tester);
      expect(find.text('Pengaturan Umum'), findsNothing);
      expect(find.text('Manajemen Tim'), findsNothing);
      expect(find.text('PROFIL BANK SAMPAH'), findsNothing);
      expect(find.text('Simpan Pengaturan'), findsNothing);
    });

    testWidgets('profil nasabah tidak meminta data pengaturan pengelola',
        (tester) async {
      await openProfile(tester);
      verifyNever(() => profile.load(silent: true));
    });
  });
}
