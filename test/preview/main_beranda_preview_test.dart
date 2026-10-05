import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/main_beranda_preview.dart' as preview;
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';

void main() {
  tearDown(() async {
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
}
