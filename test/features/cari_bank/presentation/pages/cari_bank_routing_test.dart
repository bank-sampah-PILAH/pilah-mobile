import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/router/app_router_config.dart';
import 'package:pilah_mobile/features/cari_bank/domain/entities/cari_bank_entities.dart';
import 'package:pilah_mobile/features/cari_bank/data/datasources/cari_bank_remote_data_source.dart'
    show CariBankRemoteDataSource, CariBankRemoteDataSourceImpl;
import 'package:pilah_mobile/features/cari_bank/presentation/cubit/cari_bank_cubit.dart';
import 'package:pilah_mobile/features/cari_bank/presentation/pages/bank_sampah_detail_page.dart';
import 'package:pilah_mobile/features/cari_bank/presentation/pages/cari_bank_page.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/location_service.dart';
import 'package:pilah_mobile/features/perbandingan_harga/data/datasources/perbandingan_harga_remote_data_source.dart';
import 'package:pilah_mobile/features/perbandingan_harga/presentation/cubit/perbandingan_harga_cubit.dart';
import 'package:pilah_mobile/features/perbandingan_harga/presentation/pages/perbandingan_harga_page.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:go_router/go_router.dart';

import '../../../../support/app_shell_support.dart';
import '../../../../support/cari_bank_support.dart';
import '../../../../support/perbandingan_harga_support.dart';
import '../../../../support/stub_api.dart';

const _directory = '/api/v1/bank-sampah';
const _detail = '/api/v1/bank-sampah/b1';
const _compare = '/api/v1/bank-sampah/harga-perbandingan';

class _FakeLocationService extends Mock implements LocationService {}

/// Drives the app's real router so the PIL-308/309 route builders in
/// app_router_config run: the nasabah Bank Sampah shell branch, the detail
/// page and the comparison page.
void main() {
  late AppShell shell;
  late StubApi api;

  setUp(() async {
    api = StubApi();
    shell = AppShell(api);
    await shell.registerDi();
    di.allowReassignment = true;
    di.registerFactory<CariBankCubit>(() => buildCariBankCubit(api));
    di.registerFactory<CariBankRemoteDataSource>(
        () => CariBankRemoteDataSourceImpl(api.network));
    di.registerFactory<PerbandinganHargaCubit>(
      () => PerbandinganHargaCubit(
        PerbandinganHargaRemoteDataSourceImpl(api.network),
      ),
    );
    final location = _FakeLocationService();
    when(() => location.currentLocation()).thenAnswer((_) async => null);
    di.registerSingleton<LocationService>(location);
    shell.signedInAsRole('nasabah', step: 'nasabah_dashboard');
  });

  tearDown(() async {
    await di.unregister<CariBankCubit>();
    await di.unregister<CariBankRemoteDataSource>();
    await di.unregister<PerbandinganHargaCubit>();
    await di.unregister<LocationService>();
    await shell.unregisterDi();
  });

  Future<GoRouter> boot(WidgetTester tester, String path) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = AppRouterConfig.getRouter();
    router.go(path);
    await tester
        .pumpWidget(shell.wrap(MaterialApp.router(routerConfig: router)));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('the Bank Sampah tab resolves through its shell branch',
      (tester) async {
    api.on('GET', _directory,
        json: bankSampahPage([bankRow('b1', 'Bank Garis')]));

    final router = await boot(tester, CariBankPage.route);

    expect(find.byType(CariBankPage), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.last.matchedLocation,
        CariBankPage.route);
  });

  testWidgets('the detail route builds its page from the extra id',
      (tester) async {
    api.on('GET', _directory,
        json: bankSampahPage([bankRow('b1', 'Bank Garis')]));
    api.on('GET', _detail, json: bankDetailJson());

    final router = await boot(tester, CariBankPage.route);

    router.push(BankSampahDetailPage.route, extra: 'b1');
    await tester.pumpAndSettle();

    expect(find.byType(BankSampahDetailPage), findsOneWidget);
    expect(find.text('Bank Garis'), findsWidgets);
  });

  testWidgets('the comparison route builds from its seed record',
      (tester) async {
    api.on('GET', _compare,
        json: perbandinganJson(
          nomor: 'K-1',
          namaSampah: 'Kardus',
          rows: [hargaRow('b1', 'Bank Garis', harga: '2000.00')],
        ));

    final router = await boot(tester, CariBankPage.route);

    const layanan = LayananEntity(
      id: 'ls-K-1',
      kode: 'K-1',
      namaSampah: 'Kardus',
      kategori: 'kertas',
      deskripsi: '',
      hargaPerKg: '2000.00',
      satuan: 'kg',
    );
    router.push(
      PerbandinganHargaPage.route,
      extra: const PerbandinganSeed(
        jenisSampahId: 'ls-K-1',
        bankAsalId: 'b1',
        bankAsalNama: 'Bank Garis',
        layananAsal: [layanan],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PerbandinganHargaPage), findsOneWidget);
    expect(find.text('K-1 · Kardus'), findsWidgets);
  });
}
