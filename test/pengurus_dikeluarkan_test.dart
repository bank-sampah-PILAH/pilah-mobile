import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pilah_mobile/app.dart';
import 'package:pilah_mobile/core/client/pengurus_dikeluarkan.dart';
import 'package:pilah_mobile/core/constants/endpoints.dart';
import 'package:pilah_mobile/core/router/app_router_config.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/use_cases/get_nasabah_memberships_usecase.dart';
import 'package:pilah_mobile/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/profile/domain/entities/profile_entities.dart';
import 'package:pilah_mobile/features/profile/presentation/states/profile_state.dart';
import 'package:pilah_mobile/services/di.dart';

import 'support/app_shell_support.dart';
import 'support/approved_membership.dart';
import 'support/profile_support.dart';
import 'support/stub_api.dart';

/// A pengurus the Pengurus Utama has removed finds out from the server's next
/// refusal. Wherever they are, the app sends them to the start screen for
/// someone without a bank sampah and says why.
void main() {
  late AppShell shell;
  late StubApi api;

  setUp(() async {
    api = StubApi();
    shell = AppShell(api);
    await shell.registerDi();
    di.registerSingleton<GetNasabahMembershipsUseCase>(
        buildApprovedMembershipUseCase());
    di.registerSingleton<ProfileRemoteDataSource>(
        ProfileRemoteDataSourceImpl(api.network));
    di.registerSingleton<ImagePicker>(MockImagePicker());
    di.registerSingleton<ImageCropper>(MockImageCropper());
  });

  tearDown(() async {
    AppRouterConfig.getRouter().go('/login');
    await di.unregister<GetNasabahMembershipsUseCase>();
    await di.unregister<ProfileRemoteDataSource>();
    await di.unregister<ImagePicker>();
    await di.unregister<ImageCropper>();
    await shell.unregisterDi();
  });

  Future<void> boot(WidgetTester tester, {bool isWeb = false}) async {
    AppRouterConfig.getRouter().go('/splash');
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(App(
      isWebOverride: isWeb,
      providerScopeBuilder: shell.wrap,
    ));
    addTearDown(() => tester.pumpWidget(const SizedBox()));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  String location() =>
      AppRouterConfig.getRouter().routerDelegate.currentConfiguration.uri.path;

  Future<void> evict(WidgetTester tester, String message) async {
    PengurusDikeluarkanSignal.raise(message);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('goes to the screen for a pengurus without a bank sampah',
      (tester) async {
    shell.signedInAsRole('pengelola', bankStatus: 'active');
    await boot(tester);
    expect(location(), '/dashboard');

    await evict(tester, 'Anda sudah dikeluarkan dari bank sampah ini');

    expect(location(), '/register-bank-sampah');
    expect(shell.auth.calls, contains('refreshUser'));
    expect(find.text('Anda sudah dikeluarkan dari bank sampah ini'),
        findsOneWidget);
  });

  testWidgets('what the removed pengurus cached for the bank is cleared',
      (tester) async {
    shell.signedInAsRole('pengelola', bankStatus: 'active');
    await boot(tester);
    shell.profile.setStateForTest(ProfileState(
      status: ProfileStatus.loaded,
      team: const [
        TeamMember(
          id: 'u1',
          nama: 'Siti',
          email: 'siti@x.test',
          isPrimary: true,
          isCurrentUser: true,
        ),
      ],
      selectedLogoBytes: Uint8List.fromList([1]),
      selectedLogoFilename: 'logo.png',
    ));

    await evict(tester, 'Anda sudah dikeluarkan dari bank sampah ini');

    expect(location(), '/register-bank-sampah');
    expect(shell.profile.state.status, isNot(ProfileStatus.loaded));
    expect(shell.profile.state.team, isEmpty);
    expect(shell.profile.state.selectedLogoBytes, isNull);
  });

  testWidgets('a real refusal through the network stack does the same',
      (tester) async {
    shell.signedInAsRole('pengelola', bankStatus: 'active');
    await boot(tester);
    api.on('GET', '/api/v1/team', status: 403, json: {
      'error':
          'Anda telah dikeluarkan dari bank sampah ini oleh Pengurus Utama.',
      'code': 'pengurus_dikeluarkan',
    });

    unawaited(api.network.get(Endpoints.team).then((_) {}, onError: (_) {}));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(location(), '/register-bank-sampah');
    expect(
      find.text(
          'Anda telah dikeluarkan dari bank sampah ini oleh Pengurus Utama.'),
      findsOneWidget,
    );
  });

  testWidgets('the browser app is sent away the same way', (tester) async {
    shell.signedInAsRole('pengelola', bankStatus: 'active');
    await boot(tester, isWeb: true);
    expect(location(), '/dashboard');

    await evict(tester, 'Anda sudah dikeluarkan dari bank sampah ini');

    expect(location(), '/register-bank-sampah');
    expect(find.text('Anda sudah dikeluarkan dari bank sampah ini'),
        findsOneWidget);
  });

  testWidgets('follows the step the server now reports', (tester) async {
    shell.signedInAsRole('pengelola', bankStatus: 'active');
    await boot(tester);
    shell.auth.onRefreshUser = () => shell.auth.setStateForTest(
          Authenticated(
            authEntity: const AuthEntity(
              id: 'u1',
              name: 'Siti',
              email: 'siti@example.test',
              photoUrl: '',
              token: 't',
              nextStep: 'approval_pending',
              role: 'pengelola',
            ),
          ),
        );

    await evict(tester, 'Dikeluarkan');

    expect(location(), '/pending-approval');
  });

  testWidgets('refusals that arrive together send them away only once',
      (tester) async {
    shell.signedInAsRole('pengelola', bankStatus: 'active');
    await boot(tester);
    shell.auth.onRefreshUser = () => shell.auth.setStateForTest(
          Authenticated(
            authEntity: const AuthEntity(
              id: 'u1',
              name: 'Siti',
              email: 'siti@example.test',
              photoUrl: '',
              token: 't',
              nextStep: 'register_bank_sampah',
              role: 'pengelola',
            ),
          ),
        );

    PengurusDikeluarkanSignal.raise('Dikeluarkan');
    PengurusDikeluarkanSignal.raise('Dikeluarkan');
    await evict(tester, 'Dikeluarkan');

    expect(location(), '/register-bank-sampah');
    expect(shell.auth.calls.where((c) => c == 'refreshUser').length, 1);
    expect(find.text('Dikeluarkan'), findsOneWidget);
  });

  testWidgets('a refusal that arrives after they were sent away adds nothing',
      (tester) async {
    shell.signedInAsRole('pengelola', bankStatus: 'active');
    await boot(tester);
    shell.auth.onRefreshUser = () => shell.auth.setStateForTest(
          Authenticated(
            authEntity: const AuthEntity(
              id: 'u1',
              name: 'Siti',
              email: 'siti@example.test',
              photoUrl: '',
              token: 't',
              nextStep: 'register_bank_sampah',
              role: 'pengelola',
            ),
          ),
        );
    await evict(tester, 'Dikeluarkan');

    await evict(tester, 'Dikeluarkan');

    expect(location(), '/register-bank-sampah');
    expect(find.text('Dikeluarkan'), findsOneWidget);
  });

  testWidgets('a signed-out session is left alone', (tester) async {
    shell.signedInAsRole('pengelola', bankStatus: 'active');
    await boot(tester);
    shell.auth.setStateForTest(Unauthenticated());
    await tester.pumpAndSettle();
    final where = location();

    await evict(tester, 'Dikeluarkan');

    expect(location(), where);
    expect(shell.auth.calls, isNot(contains('refreshUser')));
  });
}
