import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/legal/presentation/pages/legal_information_page.dart';
import 'package:pilah_mobile/design/layout/app_page_header.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';
import '../../../../support/auth_support.dart';
import '../../../../support/stub_api.dart';

void main() {
  testWidgets('web profile opens existing legal information and returns',
      (tester) async {
    di.registerSingleton<NasabahRepository>(PreviewNasabahRepository());
    addTearDown(di.reset);
    final auth = authNotifierIn(Authenticated(
        authEntity: const AuthEntity(
      id: 'customer',
      name: 'Siti',
      email: 'siti@example.test',
      photoUrl: '',
      token: 'token',
      role: 'nasabah',
    )));
    final router = GoRouter(initialLocation: '/profile', routes: [
      GoRoute(
          path: '/profile', builder: (_, __) => const ProfilePage(isWeb: true)),
      GoRoute(
          path: LegalInformationPage.route,
          builder: (_, __) => const LegalInformationPage()),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(withAuthenticationProvider(
        auth, MaterialApp.router(routerConfig: router)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Informasi & legal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Informasi & legal'));
    await tester.pumpAndSettle();
    expect(find.byType(LegalInformationPage), findsOneWidget);
    expect(find.text('Kebijakan Privasi'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsOneWidget);
  });

  for (final width in [390.0, 1440.0]) {
    testWidgets('web profile saves all editable fields at width $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = StubApi();
      final identity = <String, dynamic>{
        'id': 'customer',
        'nama': 'Siti Aminah',
        'email': 'siti@example.test',
        'role': 'nasabah',
        'no_hp': '081234567890',
        'jenis_kelamin': 'perempuan',
        'tanggal_lahir': '1998-05-17',
        'alamat': 'Jl. Melati',
      };
      api.onRequest('GET', '/api/v1/nasabah/me/profil', json: (_) => identity);
      api.onRequest('PATCH', '/api/v1/nasabah/me/profil', json: (request) {
        identity
            .addAll(jsonDecode(request.data as String) as Map<String, dynamic>);
        return identity;
      });
      di.registerSingleton<NasabahRepository>(NasabahRepository(api.network));
      addTearDown(di.reset);
      final auth = authNotifierIn(Authenticated(
          authEntity: const AuthEntity(
        id: 'customer',
        name: 'Siti Aminah',
        email: 'siti@example.test',
        photoUrl: '',
        token: 'token',
        role: 'nasabah',
      )));
      await tester.pumpWidget(withAuthenticationProvider(
        auth,
        const MaterialApp(home: ProfilePage(isWeb: true)),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Ubah profil'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'siti@example.test'), findsNothing);
      await tester.enterText(
          find.widgetWithText(TextField, 'Siti Aminah'), 'Siti Baru');
      await tester.enterText(
          find.widgetWithText(TextField, '081234567890'), '089900001111');
      await tester.ensureVisible(find.text('Laki-laki'));
      await tester.tap(find.text('Laki-laki'));
      await tester.ensureVisible(find.text('17/05/1998'));
      await tester.tap(find.text('17/05/1998'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('18'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextField, 'Jl. Melati'), 'Jl. Mawar');
      await tester.ensureVisible(find.text('Simpan Perubahan'));
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();

      expect(
          api.requests
              .where((request) => request.method == 'PATCH')
              .single
              .json,
          {
            'nama': 'Siti Baru',
            'no_hp': '089900001111',
            'jenis_kelamin': 'laki-laki',
            'tanggal_lahir': '1998-05-18',
            'alamat': 'Jl. Mawar',
          });
      // A fresh page load reads the saved values from the HTTP fixture.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(withAuthenticationProvider(
        authNotifierIn(Authenticated(
            authEntity: const AuthEntity(
          id: 'customer',
          name: 'Siti Aminah',
          email: 'siti@example.test',
          photoUrl: '',
          token: 'token',
          role: 'nasabah',
        ))),
        const MaterialApp(home: ProfilePage(isWeb: true)),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Siti Baru'), findsOneWidget);
      await tester.ensureVisible(find.text('Jl. Mawar'));
      expect(find.text('Jl. Mawar'), findsOneWidget);
      expect(find.text('18/05/1998'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'desktop Nasabah profile uses the web header and full-width scroll',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    di.registerSingleton<NasabahRepository>(PreviewNasabahRepository());
    addTearDown(di.reset);
    final auth = authNotifierIn(Authenticated(
        authEntity: const AuthEntity(
      id: 'customer',
      name: 'Siti',
      email: 'siti@example.test',
      photoUrl: '',
      token: 'token',
      role: 'nasabah',
    )));
    await tester.pumpWidget(withAuthenticationProvider(
      auth,
      const MaterialApp(home: ProfilePage(isWeb: true)),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(AppPageHeader), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(tester.getSize(find.byType(ListView)).width, 1440);
    await tester.tap(find.byTooltip('Ubah profil'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Simpan Perubahan'));
    expect(find.text('Simpan Perubahan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
