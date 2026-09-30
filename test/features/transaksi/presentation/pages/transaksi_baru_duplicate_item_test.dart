import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/transaksi_baru_page.dart';

void main() {
  test('jenis sampah duplicate check ignores the edited item itself', () {
    final items = [
      {'jenis_sampah_id': 'kind-1'},
      {'jenis_sampah_id': 'kind-2'},
    ];
    expect(jenisSampahSudahAda(items, 0, 'kind-1'), isFalse);
    expect(jenisSampahSudahAda(items, 0, 'kind-2'), isTrue);
  });

  test('jenis sampah duplicate check treats an empty id as shared', () {
    final items = [
      {'jenis_sampah_id': null},
      {'jenis_sampah_id': 'kind-2'},
    ];
    // Belum dipilih: null tidak boleh menghalangi item lain.
    expect(jenisSampahSudahAda(items, 0, null), isFalse);
    // Dua item kosong memilih jenis yang sama-sama belum diisi pun terdeteksi.
    expect(jenisSampahSudahAda([{'jenis_sampah_id': null}, {'jenis_sampah_id': null}], 0, null), isTrue);
  });
}
