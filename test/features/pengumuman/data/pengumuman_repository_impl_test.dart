import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/pengumuman/data/datasources/pengumuman_remote_data_source.dart';
import 'package:pilah_mobile/features/pengumuman/data/repositories/pengumuman_repository_impl.dart';
import 'package:pilah_mobile/features/pengumuman/domain/entities/pengumuman_entity.dart';

import '../../../support/stub_api.dart';

PengumumanEntity _entity({String id = ''}) => PengumumanEntity(
      id: id,
      bankSampahId: 'b',
      judul: 'Pengumuman',
      isi: 'Isi.',
    );

void main() {
  late StubApi api;
  late PengumumanRepositoryImpl repository;

  setUp(() {
    api = StubApi();
    repository =
        PengumumanRepositoryImpl(PengumumanRemoteDataSourceImpl(api.network));
  });

  test('a failed update comes back as a Left failure', () async {
    api.fail('PATCH', '/api/v1/pengumuman/9');

    final outcome = await repository.updatePengumuman(_entity(id: '9'));

    expect(outcome.isLeft(), isTrue);
  });

  test('a failed delete comes back as a Left failure', () async {
    api.fail('DELETE', '/api/v1/pengumuman/9');

    final outcome = await repository.deletePengumuman('9');

    expect(outcome.isLeft(), isTrue);
  });

  test('terbitkan forwards both schedule fields to the wire', () async {
    api.on('POST', '/api/v1/pengumuman/9/terbitkan', json: {
      'id': '9',
      'bank_sampah_id': 'b',
      'judul': 'Pengumuman',
      'isi': 'Isi.',
      'terbit_pada': '2026-10-20T03:00:00Z',
      'masa_berlaku_hingga': '2026-10-30T03:00:00Z',
      'ditarik_pada': null,
      'status': 'terbit',
    });

    final outcome = await repository.terbitkan(
      '9',
      terbitPada: DateTime.utc(2026, 10, 20, 3),
      masaBerlakuHingga: DateTime.utc(2026, 10, 30, 3),
    );

    expect(outcome.isRight(), isTrue);
    final sent = api.requests
        .firstWhere((call) => call.path == '/api/v1/pengumuman/9/terbitkan');
    expect(sent.json['masa_berlaku_hingga'], isNotNull);
  });
}
