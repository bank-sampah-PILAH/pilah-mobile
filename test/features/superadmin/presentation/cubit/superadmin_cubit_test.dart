import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/superadmin/presentation/cubit/superadmin_cubit.dart';
import 'package:pilah_mobile/features/superadmin/presentation/cubit/superadmin_state.dart';

import '../../../../support/stub_api.dart';
import '../../../../support/superadmin_support.dart';

const _path = '/api/v1/superadmin/bank-sampah';

void main() {
  late StubApi api;
  late SuperadminCubit cubit;

  setUp(() {
    api = StubApi();
    cubit = buildSuperadminCubit(api);
  });

  tearDown(() => cubit.close());

  test('loads the banks for a status, mapping the payload', () async {
    api.on('GET', _path, json: {
      'count': 2,
      'results': [
        bankRow('1', foto: 'https://img.test/a.jpg'),
        bankRow('2', foto: '', created: 'bukan tanggal', withPengelola: false),
      ],
    });

    await cubit.loadBankSampah('pending');

    expect(api.last.query, {'status': 'pending'});
    final loaded = cubit.state as SuperadminLoaded;
    expect(loaded.status, 'pending');
    expect(cubit.status, 'pending');
    final first = loaded.banks.first;
    expect(first.nama, 'Bank Melati');
    expect(first.fotoKegiatan, 'https://img.test/a.jpg');
    expect(first.pengelolaNama, 'Budi');
    expect(first.createdAt, isNotNull);
    final second = loaded.banks.last;
    expect(second.fotoKegiatan, isNull);
    expect(second.createdAt, isNull);
    expect(second.pengelolaNama, isNull);
  });

  test('accepts a bare list and fills missing fields with defaults', () async {
    api.on('GET', _path, json: [<String, dynamic>{}]);

    await cubit.loadBankSampah('active');

    final bank = (cubit.state as SuperadminLoaded).banks.single;
    expect(bank.id, '');
    expect(bank.status, 'pending');
  });

  test('a map without results is an empty list', () async {
    api.on('GET', _path, json: <String, dynamic>{});

    await cubit.loadBankSampah('rejected');

    expect((cubit.state as SuperadminLoaded).banks, isEmpty);
  });

  test('a failed load reports the backend message', () async {
    api.on('GET', _path, status: 403, json: {'error': 'Bukan superadmin'});

    await cubit.loadBankSampah('pending');

    expect(cubit.state, const SuperadminError('Bukan superadmin'));
  });

  test('a silent reload keeps the list on screen', () async {
    api.on('GET', _path, json: {
      'results': [bankRow('1')],
    });
    await cubit.loadBankSampah('pending');
    api.on('GET', _path, json: {
      'results': [bankRow('1'), bankRow('2')],
    });
    final states = <SuperadminState>[];
    final sub = cubit.stream.listen(states.add);

    await cubit.loadBankSampah('pending', silent: true);
    await pumpEventQueue();
    await sub.cancel();

    expect(states.whereType<SuperadminLoading>(), isEmpty);
    expect((states.last as SuperadminLoaded).banks, hasLength(2));
  });

  test('approve posts to the approve endpoint and reloads the tab', () async {
    api.on('GET', _path, json: {'results': []});
    api.on('POST', '$_path/b1/approve', json: {});
    await cubit.loadBankSampah('pending');

    expect(await cubit.approve('b1'), isNull);
    await pumpEventQueue();

    expect(api.requests.any((r) => r.path == '$_path/b1/approve'), isTrue);
    expect(api.requests.where((r) => r.method == 'GET'), hasLength(2));
  });

  test('reject posts to the reject endpoint', () async {
    api.on('GET', _path, json: {'results': []});
    api.on('POST', '$_path/b1/reject', json: {});

    expect(await cubit.reject('b1'), isNull);
    await pumpEventQueue();

    expect(api.requests.any((r) => r.path == '$_path/b1/reject'), isTrue);
  });

  test('approve and reject hand back the failure', () async {
    api.on('POST', '$_path/b1/approve', status: 409, json: {'error': 'Sudah'});
    api.fail('POST', '$_path/b1/reject', DioExceptionType.sendTimeout);

    expect((await cubit.approve('b1'))!.displayMessage, 'Sudah');
    expect((await cubit.reject('b1'))!.displayMessage, 'Send Timeout');
  });

  test('the data source forwards a trimmed note when one is given', () async {
    // The use cases never pass a note today, but the data layer supports it.
    api.on('POST', '$_path/b1/approve', json: {});
    api.on('POST', '$_path/b1/reject', json: {});

    final source = cubit.approveBankSampahUseCase.repository;
    await source.approve('b1', catatan: '  oke ');
    await source.reject('b1', catatan: ' alasan ');
    await source.reject('b1', catatan: '   ');

    expect(api.requests[0].json, {'catatan': 'oke'});
    expect(api.requests[1].json, {'catatan': 'alasan'});
    expect(api.requests[2].json, <String, dynamic>{});
  });

  test('states compare by value', () {
    expect(SuperadminInitial(), SuperadminInitial());
    expect(SuperadminLoading(), SuperadminLoading());
    expect(const SuperadminLoaded(banks: [], status: 'a'),
        const SuperadminLoaded(banks: [], status: 'a'));
  });
}
