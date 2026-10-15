import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_entity.dart';

Pencairan _pencairan({
  String keterangan = '',
  bool diperbarui = false,
}) =>
    Pencairan(
      id: 'p-1',
      nasabahNama: 'Ahmad Ridwan',
      nominal: 50000,
      metode: MetodePencairan.tunai,
      tanggal: DateTime(2026, 9, 22, 10),
      keterangan: keterangan,
      status: 'tercatat',
      saldoSebelum: 100000,
      saldoSesudah: 50000,
      diperbarui: diperbarui,
    );

void main() {
  group('ActivitasEntity.fromPencairan', () {
    test('shows only the metode, matching setoran\'s single-line subtitle', () {
      final entity =
          ActivitasEntity.fromPencairan(_pencairan(keterangan: 'Diambil pagi'));

      expect(
        entity.subtitleLines,
        ['Tunai'],
        reason: 'setoran rows show one subtitle line (jenis+berat) with no '
            'separate note line — pencairan should read the same way',
      );
    });

    test('never carries a badge, even for an edited record', () {
      final entity = ActivitasEntity.fromPencairan(
        _pencairan(diperbarui: true, keterangan: 'Diambil pagi'),
      );

      expect(
        entity.badge,
        isNull,
        reason: 'setoran rows never show a badge — the merged feed should '
            'not single out an edited pencairan with one either',
      );
    });
  });
}
