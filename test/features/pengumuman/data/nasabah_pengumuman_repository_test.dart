import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/pengumuman/data/nasabah_pengumuman_repository.dart';

import '../../../support/stub_api.dart';

void main() {
  late StubApi api;
  late NasabahPengumumanRepository repository;

  setUp(() {
    api = StubApi();
    repository = NasabahPengumumanRepository(api.network);
  });

  test('list maps the paginated payload', () async {
    api.on('GET', '/api/v1/nasabah/me/pengumuman', json: {
      'count': 1,
      'next': 'http://api.test/api/v1/nasabah/me/pengumuman?page=2',
      'results': [
        {
          'id': '1',
          'judul': 'Pengumuman 1',
          'isi': 'Isi 1',
          'terbit_pada': '2026-10-15T03:00:00Z',
          'dibaca': true,
        },
      ],
    });

    final page = await repository.list(membershipId: 'm-1');

    expect(page.items.single.id, '1');
    expect(page.items.single.dibaca, isTrue);
    expect(page.hasMore, isTrue);
    expect(api.last.query['keanggotaan_id'], 'm-1');
  });

  test('tandaiDibaca posts to the baca endpoint', () async {
    api.on('POST', '/api/v1/nasabah/me/pengumuman/9/baca',
        json: {'id': '9', 'dibaca': true});

    await repository.tandaiDibaca('9');

    expect(api.last.path, '/api/v1/nasabah/me/pengumuman/9/baca');
  });

  test('tandaiDibaca sends the membership scope when set', () async {
    api.on('POST', '/api/v1/nasabah/me/pengumuman/9/baca',
        json: {'id': '9', 'dibaca': true});

    await repository.tandaiDibaca('9', membershipId: 'm-1');

    expect(api.last.query['keanggotaan_id'], 'm-1');
  });

  test('tandaiDibaca maps an expired session to its message', () async {
    api.on('POST', '/api/v1/nasabah/me/pengumuman/9/baca',
        status: 401, json: {});

    await expectLater(
      repository.tandaiDibaca('9'),
      throwsA(
        isA<NasabahApiException>()
            .having((e) => e.message, 'message', contains('Sesi berakhir')),
      ),
    );
  });

  test('tandaiDibaca maps a vanished announcement to its message', () async {
    api.on('POST', '/api/v1/nasabah/me/pengumuman/9/baca',
        status: 404, json: {});

    await expectLater(
      repository.tandaiDibaca('9'),
      throwsA(
        isA<NasabahApiException>().having(
            (e) => e.message, 'message', contains('tidak lagi tersedia')),
      ),
    );
  });

  test('tandaiDibaca maps a transport failure to its message', () async {
    api.fail('POST', '/api/v1/nasabah/me/pengumuman/9/baca');

    await expectLater(
      repository.tandaiDibaca('9'),
      throwsA(
        isA<NasabahApiException>()
            .having((e) => e.message, 'message', contains('Coba lagi')),
      ),
    );
  });
}
