import 'package:flutter/foundation.dart' show setEquals;
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';

enum JenisSampahSortField { nama, harga }

/// Urutan tetap kategori yang dikenal. Kategori lain (data baru dari backend)
/// ditaruh setelahnya, kecuali `dll` yang selalu paling akhir.
const _urutanKategori = ['kertas', 'plastik', 'logam', 'kaca'];
const _kategoriLain = 'dll';

/// Cari, filter kategori, dan urutan untuk daftar jenis sampah.
///
/// Murni dan tanpa Flutter, supaya pemilih di setoran (web dan mobile) dan
/// halaman lain memakai aturan yang sama dan bisa dites tanpa widget.
class JenisSampahQuery {
  const JenisSampahQuery({
    this.search = '',
    this.kategori,
    this.sortField = JenisSampahSortField.nama,
    this.ascending = true,
  });

  final String search;

  /// Kategori yang ditampilkan. `null` berarti semua kategori, dan itulah
  /// bawaannya: memilih semua kategori selalu dinormalkan kembali menjadi
  /// `null`, jadi "semua terpilih" dan "tidak menyaring" tidak pernah berbeda.
  /// Himpunan kosong berarti sengaja tidak memilih satu pun, dan tidak ada
  /// jenis yang tampil.
  final Set<String>? kategori;
  final JenisSampahSortField sortField;
  final bool ascending;

  bool get isDefault => this == const JenisSampahQuery();

  /// Apakah ada yang menyempitkan daftar. Urutan saja tidak menyempitkan.
  bool get isFiltering => search.trim().isNotEmpty || kategori != null;

  /// Memakai [Object] sebagai penanda "tidak diubah" agar [kategori] bisa
  /// sengaja dikosongkan dengan `kategori: null`.
  JenisSampahQuery copyWith({
    String? search,
    Object? kategori = _tidakDiubah,
    JenisSampahSortField? sortField,
    bool? ascending,
  }) =>
      JenisSampahQuery(
        search: search ?? this.search,
        kategori: identical(kategori, _tidakDiubah)
            ? this.kategori
            : kategori as Set<String>?,
        sortField: sortField ?? this.sortField,
        ascending: ascending ?? this.ascending,
      );

  /// Kategori yang tercentang, dari [tersedia] (urutannya dipertahankan).
  List<String> kategoriTerpilih(List<String> tersedia) =>
      kategori == null ? tersedia : tersedia.where(kategori!.contains).toList();

  bool get tidakAdaKategori => kategori != null && kategori!.isEmpty;

  /// Mencentang atau mencabut [k]. Mencabut yang terakhir menyisakan tidak ada
  /// kategori.
  JenisSampahQuery toggleKategori(String k, List<String> tersedia) {
    final sekarang = kategoriTerpilih(tersedia).toSet();
    sekarang.contains(k) ? sekarang.remove(k) : sekarang.add(k);
    return copyWith(kategori: _normal(sekarang, tersedia));
  }

  /// Baris "Semua kategori": bila semua sudah tercentang mencabut semuanya,
  /// bila tidak memilih semuanya.
  JenisSampahQuery toggleSemuaKategori(List<String> tersedia) =>
      kategoriTerpilih(tersedia).length == tersedia.length
          ? copyWith(kategori: <String>{})
          : pilihSemuaKategori();

  JenisSampahQuery pilihSemuaKategori() => copyWith(kategori: null);

  /// Membuang kategori yang sudah tidak ada di [tersedia] (tab diganti, data
  /// dimuat ulang). Bila semua yang dipilih hilang, atau yang tersisa sudah
  /// semua, hasilnya semua kategori. Pilihan yang sengaja kosong tetap kosong.
  JenisSampahQuery sesuaikanKategori(List<String> tersedia) {
    if (kategori == null || kategori!.isEmpty) return this;
    final sisa = kategori!.intersection(tersedia.toSet());
    return copyWith(kategori: sisa.isEmpty ? null : _normal(sisa, tersedia));
  }

  static Set<String>? _normal(Set<String> pilih, List<String> tersedia) =>
      setEquals(pilih, tersedia.toSet()) ? null : pilih;

  /// Daftar baru; [items] tidak diubah.
  List<HargaEntity> apply(List<HargaEntity> items) {
    final kata = search.trim().toLowerCase();
    final hasil = items.where((item) {
      if (kategori != null && !kategori!.contains(item.category)) return false;
      if (kata.isEmpty) return true;
      return item.name.toLowerCase().contains(kata) ||
          item.kodeSampah.toLowerCase().contains(kata);
    }).toList();
    hasil.sort(_bandingkan);
    return hasil;
  }

  int _bandingkan(HargaEntity a, HargaEntity b) {
    final utama = switch (sortField) {
      JenisSampahSortField.nama => _nama(a, b),
      JenisSampahSortField.harga => a.price.compareTo(b.price),
    };
    if (utama != 0) return ascending ? utama : -utama;
    // Nilai sama selalu A-Z lalu id, apa pun arahnya, agar urutan stabil.
    final nama = _nama(a, b);
    return nama != 0 ? nama : a.id.compareTo(b.id);
  }

  static int _nama(HargaEntity a, HargaEntity b) =>
      _alami(a.name.toLowerCase(), b.name.toLowerCase());

  /// Urutan alami: angka dibandingkan sebagai angka, jadi "botol 2" mendahului
  /// "botol 10".
  static int _alami(String a, String b) {
    final potong = RegExp(r'\d+|\D+');
    final x = potong.allMatches(a).map((m) => m[0]!).toList();
    final y = potong.allMatches(b).map((m) => m[0]!).toList();
    for (var i = 0; i < x.length && i < y.length; i++) {
      final angka = _angka.hasMatch(x[i]) && _angka.hasMatch(y[i]);
      final c = angka ? _bandingkanAngka(x[i], y[i]) : x[i].compareTo(y[i]);
      if (c != 0) return c;
    }
    return x.length.compareTo(y.length);
  }

  static final _angka = RegExp(r'^\d+$');

  /// Tanpa `int.parse`, supaya deretan angka yang panjang tidak meluap.
  static int _bandingkanAngka(String a, String b) {
    final p = a.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final q = b.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    return p.length != q.length ? p.length.compareTo(q.length) : p.compareTo(q);
  }

  @override
  bool operator ==(Object other) =>
      other is JenisSampahQuery &&
      other.search == search &&
      setEquals(other.kategori, kategori) &&
      other.sortField == sortField &&
      other.ascending == ascending;

  @override
  int get hashCode => Object.hash(
      search,
      kategori == null ? null : Object.hashAllUnordered(kategori!),
      sortField,
      ascending);
}

const Object _tidakDiubah = Object();

/// Kategori yang ada di [items], tanpa yang kosong, dalam urutan tetap.
List<String> kategoriTersedia(List<HargaEntity> items) {
  final ada = items.map((e) => e.category).where((c) => c.isNotEmpty).toSet();
  int rank(String c) {
    if (c == _kategoriLain) return _urutanKategori.length + 1;
    final i = _urutanKategori.indexOf(c);
    return i == -1 ? _urutanKategori.length : i;
  }

  return ada.toList()
    ..sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      return r != 0 ? r : a.compareTo(b);
    });
}

String labelKategori(String kategori) => kategori == _kategoriLain
    ? 'Lainnya'
    : kategori[0].toUpperCase() + kategori.substring(1);

/// Tulisan pada chip filter kategori: "Semua kategori", nama kategorinya bila
/// hanya satu, atau "N kategori".
String labelFilterKategori(JenisSampahQuery query, List<String> tersedia) {
  if (query.tidakAdaKategori) return 'Tidak ada kategori';
  final terpilih = query.kategoriTerpilih(tersedia);
  if (terpilih.length == tersedia.length) {
    return 'Semua kategori';
  }
  return terpilih.length == 1
      ? labelKategori(terpilih.single)
      : '${terpilih.length} kategori';
}
