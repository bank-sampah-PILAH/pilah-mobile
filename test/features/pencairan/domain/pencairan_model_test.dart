import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/revisi_pencairan.dart';

void main() {
  test('payout request equality includes every field', () {
    final tanggal = DateTime(2026, 9, 22, 10, 30);
    final request = PencairanRequest(
      nasabahId: 'n-1',
      nominal: 150000,
      metode: MetodePencairan.transfer,
      tanggal: tanggal,
      keterangan: 'Diambil',
    );

    expect(request.props, [
      'n-1',
      150000,
      MetodePencairan.transfer,
      tanggal,
      'Diambil',
    ]);
  });

  test('payout edit equality includes every field', () {
    final tanggal = DateTime(2026, 9, 22, 10, 30);
    final request = EditPencairanRequest(
      id: 'p-1',
      nominal: 125000,
      metode: MetodePencairan.tunai,
      tanggal: tanggal,
      keterangan: 'Diambil',
      alasan: 'Salah catat',
    );

    expect(request.props, [
      'p-1',
      125000,
      MetodePencairan.tunai,
      tanggal,
      'Diambil',
      'Salah catat',
    ]);
  });

  test('payout revision equality includes every field', () {
    final tanggal = DateTime(2026, 9, 21, 9, 30);
    final diubahPada = DateTime(2026, 9, 22, 11, 5);
    final revisi = RevisiPencairan(
      versi: 1,
      tanggal: tanggal,
      nominal: 200000,
      metode: MetodePencairan.transfer,
      keterangan: 'Ditransfer',
      saldoSebelum: 300000,
      saldoSesudah: 100000,
      alasan: 'Salah catat',
      diubahOlehNama: 'Ibu Sari',
      diubahPada: diubahPada,
    );

    expect(revisi.props, [
      1,
      tanggal,
      200000,
      MetodePencairan.transfer,
      'Ditransfer',
      300000,
      100000,
      'Salah catat',
      'Ibu Sari',
      diubahPada,
    ]);
  });

  test('revision history equality includes current and replaced payouts', () {
    const pencairan = Pencairan(
      id: 'p-1',
      nasabahNama: 'Ayu',
      nominal: 150000,
      metode: MetodePencairan.transfer,
      tanggal: null,
      keterangan: '',
      status: 'tercatat',
      saldoSebelum: 200000,
      saldoSesudah: 50000,
    );
    const history = RiwayatRevisiPencairan(pencairan: pencairan, revisi: []);

    expect(history.props, [pencairan, const <RevisiPencairan>[]]);
  });
}
