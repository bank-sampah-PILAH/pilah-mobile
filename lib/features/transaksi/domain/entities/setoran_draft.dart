/// Satu item pada setoran yang belum tersimpan.
///
/// Hanya memuat apa yang menentukan sah atau tidaknya item: jenis sampah yang
/// dipilih dan beratnya. Harga sengaja tidak ada di sini — harga diisi server
/// dari harga master jenis sampah, dan angka yang ditampilkan form hanyalah
/// perkiraan.
class SetoranItemDraft {
  const SetoranItemDraft({this.jenisSampahId, this.berat = 0});

  final String? jenisSampahId;
  final double berat;

  bool get hasJenis => (jenisSampahId ?? '').trim().isNotEmpty;

  /// Berat harus lebih dari nol. Mengosongkan kolom berat pada
  /// ItemSetoranCard menghasilkan 0, dan 0 bukan setoran.
  bool get hasPositiveBerat => berat > 0;

  bool get isValid => hasJenis && hasPositiveBerat;
}

/// Alasan sebuah [SetoranDraft] belum boleh dikirim.
enum SetoranProblem {
  /// Belum ada nasabah yang dipilih.
  noNasabah,

  /// Belum ada satu pun item setoran.
  noItems,

  /// Ada item yang jenis sampahnya belum dipilih.
  itemWithoutJenis,

  /// Ada item yang beratnya nol atau negatif.
  nonPositiveBerat,
}

/// Setoran yang sedang disusun di form, beserta aturan kelayakannya.
///
/// Dipisahkan dari halamannya supaya aturan ini dapat diuji tanpa membangun
/// widget apa pun, dan supaya form telepon dan form layar lebar memakai aturan
/// yang sama alih-alih masing-masing menuliskannya (Single Responsibility).
class SetoranDraft {
  const SetoranDraft({this.nasabahId, this.items = const []});

  final String? nasabahId;
  final List<SetoranItemDraft> items;

  bool get hasNasabah => (nasabahId ?? '').trim().isNotEmpty;

  /// Seluruh alasan penolakan, bukan hanya yang pertama ditemukan: memperbaiki
  /// satu hal tidak seharusnya memunculkan masalah berikutnya satu per satu.
  Set<SetoranProblem> get problems {
    final found = <SetoranProblem>{};
    if (!hasNasabah) found.add(SetoranProblem.noNasabah);
    if (items.isEmpty) {
      found.add(SetoranProblem.noItems);
      // Daftar kosong tidak punya berat untuk dikeluhkan.
      return found;
    }
    for (final item in items) {
      if (!item.hasJenis) found.add(SetoranProblem.itemWithoutJenis);
      if (!item.hasPositiveBerat) found.add(SetoranProblem.nonPositiveBerat);
    }
    return found;
  }

  /// Indeks item yang bermasalah, supaya form dapat menandai kartunya alih-alih
  /// hanya menampilkan satu pesan umum.
  Set<int> get invalidItemIndexes => {
        for (var index = 0; index < items.length; index++)
          if (!items[index].isValid) index,
      };

  bool get isValid => problems.isEmpty;
}
