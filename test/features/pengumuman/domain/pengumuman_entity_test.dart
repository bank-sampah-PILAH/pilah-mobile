import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/cubit/pengumuman_state.dart';
import 'package:pilah_mobile/features/pengumuman/domain/entities/pengumuman_entity.dart';
import 'package:pilah_mobile/features/pengumuman/domain/entities/pengumuman_page_result.dart';

void main() {
  test('the status getters map the derived statuses', () {
    expect(
        const PengumumanEntity(id: '', bankSampahId: '', judul: '', isi: '')
            .isDraft,
        isTrue);
    for (final (status, getter) in <(String, bool Function(PengumumanEntity))>[
      ('terjadwal', (e) => e.isTerjadwal),
      ('terbit', (e) => e.isTerbit),
      ('kedaluwarsa', (e) => e.isKedaluwarsa),
      ('ditarik', (e) => e.isDitarik),
    ]) {
      final entity = PengumumanEntity(
          id: '', bankSampahId: '', judul: '', isi: '', status: status);
      expect(getter(entity), isTrue, reason: status);
      expect(entity.isDraft, isFalse);
    }
  });

  test('equal rows compare equal and pages carry their props', () {
    final a = PengumumanEntity(
        id: '1',
        bankSampahId: 'b',
        judul: 'J',
        isi: 'I',
        dibaca: true,
        dibacaPada: DateTime(2026, 1, 1));
    final b = PengumumanEntity(
        id: '1',
        bankSampahId: 'b',
        judul: 'J',
        isi: 'I',
        dibaca: true,
        dibacaPada: DateTime(2026, 1, 1));
    expect(a, equals(b));

    final page =
        PengumumanPageResult(items: [a], totalCount: 1, hasMore: false);
    final same =
        PengumumanPageResult(items: [b], totalCount: 1, hasMore: false);
    expect(page, equals(same));
    expect(page.hasMore, isFalse);
  });

  test('the sealed states compare by their props', () {
    // Equality runs the props getters that plain construction leaves cold.
    expect(PengumumanInitial(), PengumumanInitial());
    expect(PengumumanInitial().props, isEmpty);
    expect(PengumumanError('gagal'), PengumumanError('gagal'));
    expect(PengumumanError('gagal').props, ['gagal']);
    expect(PengumumanError('a'), isNot(PengumumanError('b')));
  });
}
