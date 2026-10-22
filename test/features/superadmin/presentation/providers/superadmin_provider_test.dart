import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/superadmin/domain/use_cases/approve_bank_sampah_usecase.dart';
import 'package:pilah_mobile/features/superadmin/domain/use_cases/get_bank_sampah_usecase.dart';
import 'package:pilah_mobile/features/superadmin/domain/use_cases/reject_bank_sampah_usecase.dart';
import 'package:pilah_mobile/features/superadmin/presentation/providers/superadmin_provider.dart';
import 'package:pilah_mobile/features/superadmin/presentation/cubit/superadmin_state.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../../support/stub_api.dart';
import '../../../../support/superadmin_support.dart';

const _path = '/api/v1/superadmin/bank-sampah';

void main() {
  late StubApi api;
  late ProviderContainer container;
  late ProviderSubscription<SuperadminState> keepAlive;
  late SuperadminNotifier notifier;

  setUp(() {
    api = StubApi();
    container = ProviderContainer(
      overrides: [
        superadminProvider.overrideWith(() => buildSuperadminNotifier(api)),
      ],
    );
    keepAlive =
        container.listen(superadminProvider, (_, __) {}, fireImmediately: true);
    notifier = container.read(superadminProvider.notifier);
  });

  tearDown(() {
    keepAlive.close();
    container.dispose();
  });

  test('loads the banks for a status, mapping the payload', () async {
    api.on('GET', _path, json: {
      'count': 2,
      'results': [
        bankRow('1', foto: 'https://img.test/a.jpg'),
        bankRow('2', foto: '', created: 'bukan tanggal', withPengelola: false),
      ],
    });

    await notifier.loadBankSampah('pending');

    expect(api.last.query, {'status': 'pending'});
    final loaded = container.read(superadminProvider) as SuperadminLoaded;
    expect(loaded.status, 'pending');
    expect(notifier.status, 'pending');
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

    await notifier.loadBankSampah('active');

    final bank =
        (container.read(superadminProvider) as SuperadminLoaded).banks.single;
    expect(bank.id, '');
    expect(bank.status, 'pending');
  });

  test('a map without results is an empty list', () async {
    api.on('GET', _path, json: <String, dynamic>{});

    await notifier.loadBankSampah('rejected');

    expect((container.read(superadminProvider) as SuperadminLoaded).banks,
        isEmpty);
  });

  test('a failed load reports the backend message', () async {
    api.on('GET', _path, status: 403, json: {'error': 'Bukan superadmin'});

    await notifier.loadBankSampah('pending');

    expect(container.read(superadminProvider),
        const SuperadminError('Bukan superadmin'));
  });

  test('a silent initial load still reports loading', () async {
    api.on('GET', _path, json: {'results': []});
    final states = <SuperadminState>[];
    final sub =
        container.listen(superadminProvider, (_, next) => states.add(next));

    await notifier.loadBankSampah('pending', silent: true);
    sub.close();

    expect(states.whereType<SuperadminLoading>(), hasLength(1));
  });

  test('a silent reload keeps the list on screen', () async {
    api.on('GET', _path, json: {
      'results': [bankRow('1')],
    });
    await notifier.loadBankSampah('pending');
    api.on('GET', _path, json: {
      'results': [bankRow('1'), bankRow('2')],
    });
    final states = <SuperadminState>[];
    final sub =
        container.listen(superadminProvider, (_, next) => states.add(next));

    await notifier.loadBankSampah('pending', silent: true);
    await pumpEventQueue();
    sub.close();

    expect(states.whereType<SuperadminLoading>(), isEmpty);
    expect((states.last as SuperadminLoaded).banks, hasLength(2));
  });

  test('approve posts to the approve endpoint and reloads the tab', () async {
    api.on('GET', _path, json: {'results': []});
    api.on('POST', '$_path/b1/approve', json: {});
    await notifier.loadBankSampah('pending');

    expect(await notifier.approve('b1'), isNull);
    await pumpEventQueue();

    expect(api.requests.any((r) => r.path == '$_path/b1/approve'), isTrue);
    expect(api.requests.where((r) => r.method == 'GET'), hasLength(2));
  });

  test('reject posts to the reject endpoint', () async {
    api.on('GET', _path, json: {'results': []});
    api.on('POST', '$_path/b1/reject', json: {});

    expect(await notifier.reject('b1'), isNull);
    await pumpEventQueue();

    expect(api.requests.any((r) => r.path == '$_path/b1/reject'), isTrue);
  });

  test('approve and reject hand back the failure', () async {
    api.on('POST', '$_path/b1/approve', status: 409, json: {'error': 'Sudah'});
    api.fail('POST', '$_path/b1/reject', DioExceptionType.sendTimeout);

    expect((await notifier.approve('b1'))!.displayMessage, 'Sudah');
    expect((await notifier.reject('b1'))!.displayMessage, 'Send Timeout');
  });

  test('the data source forwards a trimmed note when one is given', () async {
    api.on('POST', '$_path/b1/approve', json: {});
    api.on('POST', '$_path/b1/reject', json: {});

    final source = notifier.approveBankSampahUseCase.repository;
    await source.approve('b1', catatan: '  oke ');
    await source.reject('b1', catatan: ' alasan ');
    await source.reject('b1', catatan: '   ');

    expect(api.requests[0].json, {'catatan': 'oke'});
    expect(api.requests[1].json, {'catatan': 'alasan'});
    expect(api.requests[2].json, <String, dynamic>{});
  });

  test('pending operations do not update a disposed provider', () async {
    api.latency = const Duration(milliseconds: 10);

    Future<T> disposeDuring<T>(
        Future<T> Function(SuperadminNotifier) action) async {
      final localContainer = ProviderContainer(
        overrides: [
          superadminProvider.overrideWith(() => buildSuperadminNotifier(api)),
        ],
      );
      final sub = localContainer.listen(superadminProvider, (_, __) {},
          fireImmediately: true);
      final pending = action(localContainer.read(superadminProvider.notifier));
      sub.close();
      localContainer.dispose();
      return pending;
    }

    api.on('GET', _path, json: {'results': []});
    api.on('POST', '$_path/b1/approve', json: {});
    api.on('POST', '$_path/b1/reject', json: {});

    await disposeDuring((notifier) => notifier.loadBankSampah('pending'));
    expect(await disposeDuring((notifier) => notifier.approve('b1')), isNull);
    expect(await disposeDuring((notifier) => notifier.reject('b1')), isNull);
    expect(
        api.requests.where((request) => request.method == 'GET'), hasLength(1));
  });

  test('states compare by value', () {
    expect(SuperadminInitial(), SuperadminInitial());
    expect(SuperadminLoading(), SuperadminLoading());
    expect(const SuperadminLoaded(banks: [], status: 'a'),
        const SuperadminLoaded(banks: [], status: 'a'));
  });

  test('provider resolves its use cases from DI', () async {
    di.registerSingleton<GetBankSampahUseCase>(notifier.getBankSampahUseCase);
    di.registerSingleton<ApproveBankSampahUseCase>(
        notifier.approveBankSampahUseCase);
    di.registerSingleton<RejectBankSampahUseCase>(
        notifier.rejectBankSampahUseCase);
    final defaultContainer = ProviderContainer();
    final sub = defaultContainer.listen(superadminProvider, (_, __) {},
        fireImmediately: true);
    addTearDown(() async {
      sub.close();
      defaultContainer.dispose();
      await di.unregister<GetBankSampahUseCase>();
      await di.unregister<ApproveBankSampahUseCase>();
      await di.unregister<RejectBankSampahUseCase>();
    });

    expect(defaultContainer.read(superadminProvider), SuperadminInitial());
  });
}
