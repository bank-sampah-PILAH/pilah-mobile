import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/perbandingan_harga/presentation/cubit/perbandingan_harga_cubit.dart';
import 'package:pilah_mobile/features/perbandingan_harga/presentation/cubit/perbandingan_harga_state.dart';

import '../../../../support/perbandingan_harga_support.dart';
import '../../../../support/stub_api.dart';

const _endpoint = '/api/v1/bank-sampah/harga-perbandingan';

void main() {
  late StubApi api;
  late PerbandinganHargaCubit cubit;

  setUp(() {
    api = StubApi();
    cubit = buildPerbandinganHargaCubit(api);
  });

  tearDown(() => cubit.close());

  test('fresh load sends the ids and parses the rows in order', () async {
    api.on(
      'GET',
      _endpoint,
      json: perbandinganJson(rows: [
        hargaRow('b1', 'Bank A', harga: '3000.00'),
        hargaRow('b2', 'Bank B', harga: '2500.00'),
      ]),
    );

    await cubit.muat(jenisSampahId: 'j1', bankIds: ['b1', 'b2']);

    expect(api.last.query, {'jenis_sampah_id': 'j1', 'bank_ids': 'b1,b2'});
    final loaded = cubit.state as PerbandinganHargaLoaded;
    expect(loaded.data.jenisSampah.namaSampah, 'Plastik PET');
    expect(loaded.data.perbandingan.map((r) => r.nama), ['Bank A', 'Bank B']);
  });

  test('missing prices render as unavailable rows, not errors', () async {
    api.on(
      'GET',
      _endpoint,
      json: perbandinganJson(rows: [
        hargaRow('b1', 'Bank A', harga: '3000.00'),
        hargaRow('b2', 'Bank B', alasan: 'tanpa_jenis'),
      ]),
    );

    await cubit.muat(jenisSampahId: 'j1', bankIds: ['b1', 'b2']);

    final rows = (cubit.state as PerbandinganHargaLoaded).data.perbandingan;
    expect(rows[0].hargaTidakTersedia, isFalse);
    expect(rows[1].hargaTidakTersedia, isTrue);
    expect(rows[1].alasan, 'tanpa_jenis');
  });

  test('a backend 422 surfaces as the error state', () async {
    api.on('GET', _endpoint, status: 422, json: {
      'errors': {
        'bank_ids': ['wajib diisi']
      }
    });

    await cubit.muat(jenisSampahId: 'j1', bankIds: ['b1']);

    expect(cubit.state, isA<PerbandinganHargaError>());
  });

  test('a malformed body surfaces as the error state', () async {
    api.on('GET', _endpoint, status: 200, json: {'salah': 'bentuk'});

    await cubit.muat(jenisSampahId: 'j1', bankIds: ['b1']);

    expect(cubit.state, isA<PerbandinganHargaError>());
  });

  test('an empty bank list is a silent no-op, not a broken call', () async {
    await cubit.muat(jenisSampahId: 'j1', bankIds: const []);

    expect(api.requests, isEmpty);
  });
}
