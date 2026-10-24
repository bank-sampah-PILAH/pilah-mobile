import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/cari_bank/presentation/cubit/cari_bank_cubit.dart';
import 'package:pilah_mobile/features/cari_bank/presentation/cubit/cari_bank_state.dart';

import '../../../../support/cari_bank_support.dart';
import '../../../../support/stub_api.dart';

const _directory = '/api/v1/bank-sampah';

void main() {
  late StubApi api;
  late CariBankCubit cubit;

  setUp(() {
    api = StubApi();
    cubit = buildCariBankCubit(api);
  });

  tearDown(() => cubit.close());

  test('the first load sends page 1 and parses the envelope', () async {
    api.on('GET', _directory,
        json: bankSampahPage([bankRow('b1', 'Bank Garis')], count: 1));

    await cubit.load();

    expect(api.last.query, {'page': '1'});
    expect((cubit.state as CariBankLoaded).items.first.nama, 'Bank Garis');
    expect((cubit.state as CariBankLoaded).hasMore, isFalse);
  });

  test('the keyword and kota filters travel as q and kota', () async {
    api.on('GET', _directory, json: bankSampahPage(const [], count: 0));

    cubit.ketikKataKunci('  mawar ');
    await Future<void>.delayed(CariBankCubit.jedaPencarian * 2);

    cubit.ketikKota(' Depok ');
    await Future<void>.delayed(CariBankCubit.jedaPencarian * 2);

    // Two separate debounced loads, each carrying its latest filter.
    expect(api.requests, hasLength(2));
    expect(api.requests.first.query, {'page': '1', 'q': 'mawar'});
    expect(
        api.requests.last.query, {'page': '1', 'q': 'mawar', 'kota': 'Depok'});
  });

  test('typing inside the debounce window collapses to one request', () async {
    api.on('GET', _directory, json: bankSampahPage(const [], count: 0));

    cubit.ketikKataKunci('ma');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    cubit.ketikKataKunci('mawar');
    await Future<void>.delayed(CariBankCubit.jedaPencarian * 2);

    expect(api.requests, hasLength(1));
    expect(api.last.query['q'], 'mawar');
  });

  test('muatBerikutnya appends the next page then honors the last one',
      () async {
    api.on('GET', _directory,
        json: bankSampahPage([bankRow('b1', 'Bank Garis')],
            count: 2, hasNext: true));
    await cubit.load();

    api.on('GET', _directory,
        json: bankSampahPage([bankRow('b2', 'Bank Mawar')], count: 2));
    await cubit.muatBerikutnya();

    expect(api.last.query, {'page': '2'});
    final loaded = cubit.state as CariBankLoaded;
    expect(loaded.items.map((b) => b.id), ['b1', 'b2']);
    expect(loaded.hasMore, isFalse);
    expect(loaded.totalCount, 2);

    // A third attempt is a no-op: the last page was reached.
    api.requests.clear();
    await cubit.muatBerikutnya();
    expect(api.requests, isEmpty);
  });

  test('a failed load emits the error state', () async {
    api.on('GET', _directory, status: 500, json: {});

    await cubit.load();

    expect((cubit.state as CariBankError).message, isNotEmpty);
  });

  test('a stale first-page response cannot overwrite a newer query', () async {
    api.on('GET', _directory, json: bankSampahPage(const [], count: 0));

    final stale = cubit.load();
    // Invalidate the first page before it answers by scheduling a fresh load.
    cubit.ketikKataKunci('mawar');
    await Future<void>.delayed(CariBankCubit.jedaPencarian * 2);
    await stale;

    final loaded = cubit.state as CariBankLoaded;
    expect(loaded.searchQuery, 'mawar');
  });
  test('same-value ketik and radius calls are no-ops without a reload',
      () async {
    api.on('GET', _directory, json: bankSampahPage(const [], count: 0));

    cubit.ketikKataKunci('mawar');
    await Future<void>.delayed(CariBankCubit.jedaPencarian * 2);
    final jumlah = api.requests.length;

    // Guards: same value after trim, and radius while none is active.
    cubit.ketikKataKunci('mawar');
    cubit.ketikKota('');
    cubit.pilihRadiusKm(5);
    await Future<void>.delayed(CariBankCubit.jedaPencarian * 2);

    expect(api.requests, hasLength(jumlah));
  });

  test('muatBerikutnya while a page fetch is already running fires once',
      () async {
    api.on('GET', _directory,
        json: bankSampahPage([bankRow('b1', 'Bank Garis')],
            count: 3, hasNext: true));
    await cubit.load();

    // A slow page-2 keeps the in-flight window open long enough for a second
    // scroll event to land inside it; it must not queue a duplicate call.
    api.on('GET', _directory,
        json: bankSampahPage(
          [bankRow('b2', 'Bank Mawar')],
          count: 3,
          hasNext: true,
        ));
    api.latency = const Duration(milliseconds: 200);
    try {
      final pertama = cubit.muatBerikutnya();
      final kedua = cubit.muatBerikutnya();
      await pertama;
      await kedua;
    } finally {
      api.latency = null;
    }

    final halamanDua = api.requests.where((r) => r.query['page'] == '2');
    expect(halamanDua, hasLength(1));
  });

  test('a failed muatBerikutnya surfaces the error state instead of appending',
      () async {
    api.on('GET', _directory,
        json: bankSampahPage([bankRow('b1', 'Bank Garis')],
            count: 2, hasNext: true));
    await cubit.load();

    api.on('GET', _directory, status: 500, json: {});
    await cubit.muatBerikutnya();

    // A failed append surfaces the error state (the user's retry door), not
    // a silently truncated list.
    expect(cubit.state, isA<CariBankError>());
    expect((cubit.state as CariBankError).message, isNotEmpty);
  });
}
