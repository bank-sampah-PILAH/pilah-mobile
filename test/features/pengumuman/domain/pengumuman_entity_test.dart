import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/pengumuman/domain/entities/pengumuman_entity.dart';
import 'package:pilah_mobile/features/pengumuman/domain/entities/pengumuman_page_result.dart';

void main() {
  test('each effective status has its predicate', () {
    expect(
        const PengumumanEntity(id: '1', bankSampahId: '', judul: '', isi: '')
            .isDraft,
        isTrue);
    expect(
        const PengumumanEntity(
                id: '1',
                bankSampahId: '',
                judul: '',
                isi: '',
                status: 'terjadwal')
            .isTerjadwal,
        isTrue);
    expect(
        const PengumumanEntity(
                id: '1', bankSampahId: '', judul: '', isi: '', status: 'terbit')
            .isTerbit,
        isTrue);
    expect(
        const PengumumanEntity(
                id: '1',
                bankSampahId: '',
                judul: '',
                isi: '',
                status: 'kedaluwarsa')
            .isKedaluwarsa,
        isTrue);
    expect(
        const PengumumanEntity(
                id: '1',
                bankSampahId: '',
                judul: '',
                isi: '',
                status: 'ditarik')
            .isDitarik,
        isTrue);
  });

  test('isBaru is a published row that was never withdrawn', () {
    const terbit = PengumumanEntity(
        id: '1', bankSampahId: '', judul: '', isi: '', status: 'terbit');
    final ditarik = PengumumanEntity(
      id: '1',
      bankSampahId: '',
      judul: '',
      isi: '',
      status: 'terbit',
      ditarikPada: DateTime(2026),
    );
    expect(terbit.isBaru, isTrue);
    expect(ditarik.isBaru, isFalse);
    expect(
        const PengumumanEntity(id: '1', bankSampahId: '', judul: '', isi: '')
            .isBaru,
        isFalse);
  });

  test('two entities with the same fields are equal', () {
    final a = PengumumanEntity(
      id: '1',
      bankSampahId: 'b',
      judul: 'j',
      isi: 'i',
      terbitPada: DateTime(2026),
      masaBerlakuHingga: DateTime(2027),
      ditarikPada: null,
      status: 'terbit',
    );
    final b = PengumumanEntity(
      id: '1',
      bankSampahId: 'b',
      judul: 'j',
      isi: 'i',
      terbitPada: DateTime(2026),
      masaBerlakuHingga: DateTime(2027),
      ditarikPada: null,
      status: 'terbit',
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('page results with the same fields are equal', () {
    const row = PengumumanEntity(id: '1', bankSampahId: '', judul: '', isi: '');
    final result =
        PengumumanPageResult(items: [row], totalCount: 1, hasMore: false);
    final same =
        PengumumanPageResult(items: [row], totalCount: 1, hasMore: false);
    expect(result, same);
    expect(result.hashCode, same.hashCode);
  });
}
