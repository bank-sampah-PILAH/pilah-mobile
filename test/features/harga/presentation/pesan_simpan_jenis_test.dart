import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/pesan_simpan_jenis.dart';

void main() {
  test('a new jenis is announced as added', () {
    expect(
      pesanSimpanJenis(isEditMode: false, hargaBerubah: true),
      'Jenis sampah baru berhasil ditambahkan.',
    );
  });

  test('a scheduled price names its start date', () {
    expect(
      pesanSimpanJenis(
        isEditMode: true,
        hargaBerubah: true,
        berlakuMulai: DateTime(2026, 10, 15),
      ),
      'Harga baru berlaku mulai 15 Oktober 2026.',
    );
  });

  test('any other edit is announced as updated', () {
    expect(
      pesanSimpanJenis(isEditMode: true, hargaBerubah: true),
      'Jenis sampah berhasil diperbarui.',
    );
    expect(
      pesanSimpanJenis(
        isEditMode: true,
        hargaBerubah: false,
        berlakuMulai: DateTime(2026, 10, 15),
      ),
      'Jenis sampah berhasil diperbarui.',
    );
  });
}
