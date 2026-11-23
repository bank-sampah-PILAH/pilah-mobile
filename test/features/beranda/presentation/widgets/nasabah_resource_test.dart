import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_list_page.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_resource.dart';

void main() {
  testWidgets('ignores a reload callback after its resource is disposed', (
    tester,
  ) async {
    Future<void> Function()? reload;
    var loadCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: NasabahResource<int>(
          load: () async => ++loadCount,
          registerReload: (callback) => reload = callback,
          builder: (_, value) => Text('$value'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final staleReload = reload!;

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await staleReload();

    expect(loadCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a refused bank offers the other banks, not a retry',
      (tester) async {
    String? opened;
    var loadCount = 0;
    final router = GoRouter(initialLocation: '/beranda', routes: [
      GoRoute(
        path: '/beranda',
        builder: (_, __) => NasabahResource<int>(
          load: () async {
            loadCount++;
            throw const NasabahApiException(
              'Keanggotaan dan bank sampah harus aktif.',
              statusCode: 403,
            );
          },
          builder: (_, value) => Text('$value'),
        ),
      ),
      GoRoute(
        path: ApprovalBankSampahListPage.route,
        builder: (_, state) {
          opened = state.uri.toString();
          return const Scaffold(body: Text('Bank Sampah Saya'));
        },
      ),
    ]);
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(
        find.text('Keanggotaan dan bank sampah harus aktif.'), findsOneWidget);
    // A refusal is the answer, not a hiccup: the same request would be refused
    // again, so the way out is another bank.
    expect(find.text('Coba lagi'), findsNothing);

    await tester.tap(find.text('Bank sampah saya'));
    await tester.pumpAndSettle();

    expect(opened, ApprovalBankSampahListPage.route);
    expect(loadCount, 1);
  });
}
