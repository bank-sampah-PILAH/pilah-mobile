import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:pilah_mobile/design/layout/app_page_header.dart';
import 'package:pilah_mobile/design/widgets/app_tap_target.dart';
import 'package:pilah_mobile/design/widgets/nasabah_page_app_bar.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/beranda/presentation/pages/beranda_nasabah_page.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_page_result.dart';
import 'package:pilah_mobile/features/jadwal/domain/repositories/jadwal_repository.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/web_content_surface.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../support/auth_support.dart';

class _JadwalRepository extends Mock implements JadwalRepository {}

void main() {
  late TestAuthenticationNotifier auth;

  setUp(() {
    auth = authNotifierIn(Authenticated(
      authEntity: AuthEntity(
        id: 'nasabah-1',
        name: 'Siti',
        email: 'siti@example.test',
        photoUrl: '',
        token: 'token',
        role: 'nasabah',
        nextStep: 'nasabah_dashboard',
      ),
    ));
    final jadwal = _JadwalRepository();
    when(() => jadwal.getJadwal(page: 1, date: null)).thenAnswer(
      (_) async => const Right(
          JadwalPageResult(items: [], totalCount: 0, hasMore: false)),
    );
    di.registerSingleton<JadwalRepository>(jadwal);
    di.registerSingleton<NasabahRepository>(PreviewNasabahRepository());
  });

  tearDown(() async {
    await di.unregister<NasabahRepository>();
    await di.unregister<JadwalRepository>();
  });

  Future<void> pump(
    WidgetTester tester, {
    required Size window,
    bool inWebShell = false,
  }) async {
    tester.view.physicalSize = window;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Widget page = const BerandaNasabahPage();
    if (inWebShell) page = WebContentSurface(child: page);
    await tester.pumpWidget(withAuthenticationProvider(
      auth,
      MaterialApp(home: page),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('a wide browser shows the web page header, not the app bar',
      (tester) async {
    await pump(tester, window: const Size(1440, 900), inWebShell: true);

    expect(find.byType(AppPageHeader), findsOneWidget);
    expect(find.byType(NasabahPageAppBar), findsNothing);
    expect(find.text('Beranda'), findsOneWidget);
  });

  testWidgets('the web header keeps balance, bank detail and schedule',
      (tester) async {
    await pump(tester, window: const Size(1440, 900), inWebShell: true);

    expect(find.textContaining('SALDO DI'), findsOneWidget);
    expect(find.text('Detail Bank Sampah'), findsOneWidget);
    expect(find.text('Jadwal Terdekat'), findsOneWidget);
    expect(find.byType(AppTapTarget), findsOneWidget);
  });

  testWidgets('a tablet-width browser also gets the web page header',
      (tester) async {
    await pump(tester, window: const Size(700, 900), inWebShell: true);

    expect(find.byType(AppPageHeader), findsOneWidget);
  });

  testWidgets('a browser without the rail (drawer form) keeps the app bar',
      (tester) async {
    await pump(tester, window: const Size(390, 844));

    expect(find.byType(AppPageHeader), findsNothing);
    expect(find.byType(NasabahPageAppBar), findsOneWidget);
  });

  testWidgets('the native app keeps the app bar even on a wide window',
      (tester) async {
    await pump(tester, window: const Size(1440, 900));

    expect(find.byType(AppPageHeader), findsNothing);
    expect(find.byType(NasabahPageAppBar), findsOneWidget);
  });

  testWidgets('inside the web shell the page is painted white', (tester) async {
    await pump(tester, window: const Size(1440, 900), inWebShell: true);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, Colors.white);
  });

  testWidgets('the app bar avatar still opens Profil', (tester) async {
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const BerandaNasabahPage()),
      GoRoute(
        path: AppLocations.profile,
        builder: (_, __) => const Text('halaman profil'),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(withAuthenticationProvider(
      auth,
      MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Profil'));
    await tester.pumpAndSettle();

    expect(find.text('halaman profil'), findsOneWidget);
  });
}
