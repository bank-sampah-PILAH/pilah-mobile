import 'package:pilah_mobile/features/riwayat/domain/repositories/riwayat_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:pilah_mobile/features/beranda/presentation/pages/beranda_nasabah_page.dart';
import 'package:pilah_mobile/features/profile/presentation/pages/profil_nasabah_page.dart';
import 'package:pilah_mobile/features/riwayat/presentation/pages/nasabah_history_screen.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/main_beranda_preview.dart' as preview;
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/features/pengumuman/data/nasabah_pengumuman_repository.dart';
import 'package:pilah_mobile/services/di.dart';
import '../support/stub_api.dart';

void main() {
  tearDown(() async {
    if (di.isRegistered<RiwayatRepository>()) {
      await di.unregister<RiwayatRepository>();
    }
    if (di.isRegistered<NasabahRepository>()) {
      await di.unregister<NasabahRepository>();
    }
  });

  testWidgets('preview entrypoint shows the offline Beranda for Siti',
      (tester) async {
    await tester.pumpWidget(preview.buildPreviewApp());
    final router = GoRouter.of(tester.element(find.byType(BerandaNasabahPage)));
    addTearDown(router.dispose);
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.textContaining('Siti Aminah'), findsWidgets);
    expect(di.isRegistered<NasabahRepository>(), isTrue);
  });

  testWidgets('keeps an already registered repository', (tester) async {
    di.registerSingleton<NasabahRepository>(
        PreviewNasabahRepository(bankName: 'Bank Terdaftar'));
    // The beranda page resolves the pengumuman section from the service
    // locator, so the stub API behind it needs the same registration. A
    // previous preview.main() may have already left a registration behind.
    if (di.isRegistered<NasabahPengumumanRepository>()) {
      await di.unregister<NasabahPengumumanRepository>();
    }
    final pengumumanApi = StubApi();
    pengumumanApi.on('GET', '/api/v1/nasabah/me/pengumuman/beranda',
        json: {'items': [], 'unread_count': 0});
    di.registerSingleton<NasabahPengumumanRepository>(
        NasabahPengumumanRepository(pengumumanApi.network));
    addTearDown(() => di.unregister<NasabahPengumumanRepository>());
    await tester.pumpWidget(preview.buildPreviewApp());
    final router = GoRouter.of(tester.element(find.byType(BerandaNasabahPage)));
    addTearDown(router.dispose);
    await tester.pump(const Duration(seconds: 1));
    // Drain the beranda's pengumuman request so no timer outlives the test.
    await tester.pumpAndSettle();
    expect(find.textContaining('Bank Terdaftar'), findsWidgets);
  });

  testWidgets('the preview router also serves history and profile',
      (tester) async {
    await tester.pumpWidget(preview.buildPreviewApp());
    await tester.pump(const Duration(seconds: 1));
    final router = GoRouter.of(tester.element(find.byType(BerandaNasabahPage)));
    addTearDown(router.dispose);

    router.go('${AppLocations.history}?keanggotaan_id=m1');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(NasabahHistoryScreen), findsOneWidget);

    router.go(AppLocations.profile);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ProfilNasabahPage), findsOneWidget);
  });
}
