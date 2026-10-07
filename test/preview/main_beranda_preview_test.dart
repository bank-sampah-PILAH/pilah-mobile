import 'package:pilah_mobile/features/riwayat/presentation/cubit/riwayat_history_cubit.dart';
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
import 'package:pilah_mobile/services/di.dart';

void main() {
  tearDown(() async {
    if (di.isRegistered<RiwayatHistoryCubit>()) {
      await di.unregister<RiwayatHistoryCubit>();
    }
    if (di.isRegistered<NasabahRepository>()) {
      await di.unregister<NasabahRepository>();
    }
  });

  testWidgets('preview entrypoint shows the offline Beranda for Siti',
      (tester) async {
    preview.main();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.textContaining('Siti Aminah'), findsWidgets);
    expect(di.isRegistered<NasabahRepository>(), isTrue);
  });

  testWidgets('keeps an already registered repository', (tester) async {
    di.registerSingleton<NasabahRepository>(
        PreviewNasabahRepository(bankName: 'Bank Terdaftar'));
    preview.main();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Bank Terdaftar'), findsWidgets);
  });

  testWidgets('the preview router also serves history and profile',
      (tester) async {
    preview.main();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final router = GoRouter.of(tester.element(find.byType(BerandaNasabahPage)));

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
