import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/harga/data/datasources/harga_remote_data_source_impl.dart';
import 'package:pilah_mobile/features/harga/data/repositories/harga_repository_impl.dart';
import 'package:pilah_mobile/features/harga/domain/entities/versi_harga.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/get_riwayat_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/presentation/providers/riwayat_harga_provider.dart';

import '../../../../support/stub_api.dart';

void main() {
  const path = '/api/v1/jenis-sampah/j-1/harga';
  late StubApi api;
  late ProviderContainer container;
  late RiwayatHargaNotifier notifier;
  late ProviderSubscription<RiwayatHargaState> subscription;

  setUp(() {
    api = StubApi();
    final repository =
        HargaRepositoryImpl(HargaRemoteDataSourceImpl(api.network));
    container = ProviderContainer(overrides: [
      riwayatHargaProvider.overrideWith(
        () => RiwayatHargaNotifier(GetRiwayatHargaUseCase(repository)),
      ),
    ]);
    subscription = container.listen(riwayatHargaProvider, (_, __) {});
    notifier = container.read(riwayatHargaProvider.notifier);
  });

  tearDown(() {
    subscription.close();
    container.dispose();
  });

  test('loads the versions of one jenis', () async {
    api.on('GET', path, json: {
      'results': [
        {
          'id': 1,
          'harga_per_kg': '3500.00',
          'satuan': 'kg',
          'berlaku_mulai': '2026-09-01T03:00:00Z',
          'dibuat_oleh': 'Ibu Sari',
          'status': 'berlaku',
        },
      ],
    });

    await notifier.load('j-1');

    expect(notifier.state.status, RiwayatHargaStatus.loaded);
    expect(notifier.state.riwayat.map((v) => (v.hargaSen, v.status)), [
      (350000, StatusVersiHarga.berlaku),
    ]);
  });

  test('a failed load says why and keeps no rows', () async {
    api.fail('GET', path);

    await notifier.load('j-1');

    expect(notifier.state.status, RiwayatHargaStatus.failure);
    expect(notifier.state.errorMessage, isNotEmpty);
    expect(notifier.state.riwayat, isEmpty);
  });
}
