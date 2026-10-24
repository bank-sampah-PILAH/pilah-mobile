import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/perbandingan_harga/domain/entities/perbandingan_harga_entities.dart';
import 'package:pilah_mobile/features/perbandingan_harga/presentation/cubit/perbandingan_harga_state.dart';

void main() {
  test('state props expose the payload they carry', () {
    expect(PerbandinganHargaLoading().props, isEmpty);
    expect(const PerbandinganHargaError('gagal').props, ['gagal']);
    const data = PerbandinganHargaEntity(
      jenisSampah: PerbandinganJenisEntity(
        id: 'j1',
        nomor: 'K-1',
        namaSampah: 'Kardus',
        kategori: 'kertas',
        satuan: 'kg',
      ),
      perbandingan: [],
    );
    const loaded = PerbandinganHargaLoaded(data);
    expect(loaded.props, [data]);
    expect(const PerbandinganHargaLoaded(data), loaded);
  });
}
