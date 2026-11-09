/// Pesan kesalahan sebuah kartu item setoran, satu rumusan untuk dua form.
///
/// Transaksi Baru (`setoran_form_view.dart`) dan Edit Setoran
/// (`edit_setoran_sheet.dart`) memeriksa isi kartu yang sama dengan aturan
/// yang sama: tanpa jenis sampah, beratnya belum berarti apa pun, jadi jenis
/// dilaporkan lebih dulu. Keduanya dulu menulis urutan dan bunyi pesannya
/// masing-masing.
///
/// Salinan itu memang sempat berbeda. Pada Edit Setoran, "Tambah Item"
/// melahirkan kartu tanpa `jenis_sampah_id` sementara pesannya hanya bicara
/// soal berat, jadi Simpan Perubahan mati tanpa sebab yang terlihat; Transaksi
/// Baru sudah benar di titik itu. Satu aturan di dua tempat adalah dua
/// kesempatan untuk berbeda, dan yang satu sudah terlanjur.
///
/// Template Method: [messageFor] memegang bagian yang tetap, yaitu urutan
/// pemeriksaan dan bunyi kedua pesan. Yang diserahkan ke pemanggil hanya
/// langkah yang memang berbeda antar form, yaitu bagaimana satu kartu dibaca
/// dan kapan jenis yang kosong layak dikeluhkan.
abstract class ItemSetoranProblemReporter {
  const ItemSetoranProblemReporter();

  /// Jumlah kartu yang ada sekarang.
  ///
  /// Dipakai [messageFor] sebagai penjaga: sebuah frame dapat meminta pesan
  /// untuk kartu yang baru saja dihapus.
  int get itemCount;

  /// Apakah kartu ke-[index] sudah punya jenis sampah.
  bool hasJenis(int index);

  /// Apakah berat kartu ke-[index] lebih dari 0.
  bool hasPositiveBerat(int index);

  /// Apakah jenis yang belum dipilih pada kartu ke-[index] sudah layak
  /// dikeluhkan.
  ///
  /// Inilah satu-satunya alasan kedua form pernah berbeda. Pada Transaksi
  /// Baru, kartu baru memang lahir tanpa jenis, jadi menandainya sebelum
  /// simpan ditekan berarti mengomeli pengelola yang belum melakukan apa pun.
  /// Pada Edit Setoran tidak ada "sebelum simpan ditekan" yang setara:
  /// tombolnya hanya mati, jadi diam berarti tidak ada yang menjelaskan
  /// kematiannya.
  bool reportsMissingJenis(int index);

  /// Pesan untuk kartu ke-[index], atau null bila tidak ada yang salah.
  String? messageFor(int index) {
    if (index < 0 || index >= itemCount) return null;
    if (reportsMissingJenis(index) && !hasJenis(index)) {
      return 'Pilih jenis sampah';
    }
    if (!hasPositiveBerat(index)) return 'Berat harus lebih dari 0';
    return null;
  }
}
