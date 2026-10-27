import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/pengumuman/data/datasources/pengumuman_remote_data_source.dart';
import 'package:pilah_mobile/features/pengumuman/data/models/pengumuman_model.dart';
import 'package:pilah_mobile/features/pengumuman/data/nasabah_pengumuman_repository.dart';
import 'package:pilah_mobile/features/pengumuman/data/repositories/pengumuman_repository_impl.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';

import '../../../support/stub_api.dart';

Map<String, dynamic> _row(String id) => {
      'id': id,
      'bank_sampah_id': 'bank-1',
      'judul': 'Judul $id',
      'isi': 'Isi $id',
      'terbit_pada': '2026-10-15T03:00:00Z',
      'masa_berlaku_hingga': null,
      'ditarik_pada': null,
      'status': 'terbit',
    };

void main() {
  late StubApi api;
  late PengumumanRepositoryImpl repository;
  late NasabahPengumumanRepository nasabahRepository;

  setUp(() {
    api = StubApi();
    repository =
        PengumumanRepositoryImpl(PengumumanRemoteDataSourceImpl(api.network));
    nasabahRepository = NasabahPengumumanRepository(api.network);
  });

  group('PengumumanRepositoryImpl maps transport failures to Left', () {
    test('getPengumuman', () async {
      api.fail('GET', '/api/v1/pengumuman');
      final result = await repository.getPengumuman(page: 1);
      expect(result.isLeft(), isTrue);
    });

    test('createPengumuman', () async {
      api.fail('POST', '/api/v1/pengumuman');
      final result = await repository.createPengumuman(const PengumumanModel(
          id: '', bankSampahId: '', judul: 'J', isi: 'I'));
      expect(result.isLeft(), isTrue);
    });

    test('updatePengumuman', () async {
      api.fail('PATCH', '/api/v1/pengumuman/9');
      final result = await repository.updatePengumuman(const PengumumanModel(
          id: '9', bankSampahId: '', judul: 'J', isi: 'I'));
      expect(result.isLeft(), isTrue);
    });

    test('terbitkan with schedule times sends them as ISO strings', () async {
      final time = DateTime(2026, 12, 1, 9);
      api.on('POST', '/api/v1/pengumuman/9/terbitkan', json: _row('9'));

      final result = await repository.terbitkan('9',
          terbitPada: time,
          masaBerlakuHingga: time.add(const Duration(days: 1)));

      expect(result.isRight(), isTrue);
      final body = api.last.json;
      expect(body['terbit_pada'], isNotNull);
      expect(body['masa_berlaku_hingga'], isNotNull);
    });

    test('terbitkan failure', () async {
      api.fail('POST', '/api/v1/pengumuman/9/terbitkan');
      expect((await repository.terbitkan('9')).isLeft(), isTrue);
    });

    test('tarik', () async {
      api.fail('POST', '/api/v1/pengumuman/9/tarik');
      expect((await repository.tarik('9')).isLeft(), isTrue);
    });

    test('deletePengumuman', () async {
      api.fail('DELETE', '/api/v1/pengumuman/9');
      expect((await repository.deletePengumuman('9')).isLeft(), isTrue);
    });

    test('deletePengumuman success returns Right', () async {
      api.on('DELETE', '/api/v1/pengumuman/9', json: null);
      expect((await repository.deletePengumuman('9')).isRight(), isTrue);
    });
  });

  group('NasabahPengumumanRepository.error messages', () {
    test('list and beranda failures throw with an Indonesian message',
        () async {
      api.fail('GET', '/api/v1/nasabah/me/pengumuman');
      api.fail('GET', '/api/v1/nasabah/me/pengumuman/beranda');

      await expectLater(
        nasabahRepository.list(membershipId: 'm-1'),
        throwsA(isA<NasabahApiException>()),
      );
      await expectLater(
        nasabahRepository.getBeranda(membershipId: 'm-1'),
        throwsA(isA<NasabahApiException>()),
      );
    });

    test('tandaiDibaca maps 401, 404 and other failures distinctly', () async {
      Future<String?> message(int status) async {
        api.on('POST', '/api/v1/nasabah/me/pengumuman/1/baca',
            status: status, json: {});
        try {
          await nasabahRepository.tandaiDibaca('1');
          return null;
        } on NasabahApiException catch (error) {
          return error.message;
        }
      }

      expect(await message(401), 'Sesi berakhir. Silakan masuk kembali.');
      expect(await message(404), 'Pengumuman tidak lagi tersedia.');
      final other = await message(500);
      expect(other, 'Penanda sudah dibaca gagal. Coba lagi.');
    });
  });
}
