import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/layout/app_page_header.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';
import '../../../../support/auth_support.dart';

void main() {
  testWidgets('desktop Nasabah profile uses the web header and full-width scroll',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    di.registerSingleton<NasabahRepository>(PreviewNasabahRepository());
    addTearDown(di.reset);
    final auth = authNotifierIn(Authenticated(authEntity: const AuthEntity(
      id: 'customer', name: 'Siti', email: 'siti@example.test',
      photoUrl: '', token: 'token', role: 'nasabah',
    )));
    await tester.pumpWidget(withAuthenticationProvider(auth,
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
