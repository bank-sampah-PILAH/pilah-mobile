import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/domain/models/jenis_sampah_query.dart';

HargaEntity jenis(String id, String name, int price, String category,
        {String kode = ''}) =>
    HargaEntity(
      id: id,
      kodeSampah: kode,
      name: name,
      price: price,
      priceFormatted: 'Rp $price',
      category: category,
      subtitle: '',
      badgeText: '',
      icon: Icons.recycling,
      iconColor: Colors.green,
      isActive: true,
    );

void main() {
  final botol = jenis('1', 'Botol PET', 3000, 'plastik', kode: 'PL-01');
  final kardus = jenis('2', 'Kardus', 2000, 'kertas', kode: 'KR-01');
  final besi = jenis('3', 'Besi tua', 5000, 'logam');
  final gelas = jenis('4', 'Gelas Plastik', 3000, 'plastik');
  final lain = jenis('5', 'Minyak jelantah', 4000, 'dll');
  final all = [kardus, lain, gelas, besi, botol];

  List<String> ids(List<HargaEntity> l) => l.map((e) => e.id).toList();

  group('urutan bawaan', () {
    test('nama A-Z tanpa membedakan huruf besar kecil', () {
      expect(
          ids(const JenisSampahQuery().apply(all)), ['3', '1', '4', '2', '5']);
    });

    test('isDefault hanya benar untuk query bawaan', () {
      expect(const JenisSampahQuery().isDefault, isTrue);
      expect(const JenisSampahQuery(search: 'a').isDefault, isFalse);
      expect(const JenisSampahQuery(kategori: {'plastik'}).isDefault, isFalse);
      expect(const JenisSampahQuery(ascending: false).isDefault, isFalse);
      expect(
          const JenisSampahQuery(sortField: JenisSampahSortField.harga)
              .isDefault,
          isFalse);
    });
  });

  group('cari', () {
    test('mencocokkan sebagian nama tanpa membedakan huruf', () {
      expect(ids(const JenisSampahQuery(search: 'BOTOL').apply(all)), ['1']);
    });

    test('spasi di pinggir diabaikan, kosong berarti semua', () {
      expect(ids(const JenisSampahQuery(search: ' kardus ').apply(all)), ['2']);
      expect(const JenisSampahQuery(search: '   ').apply(all), hasLength(5));
    });

    test('mencocokkan kode sampah', () {
      expect(ids(const JenisSampahQuery(search: 'kr-01').apply(all)), ['2']);
    });

    test('kategori tidak ikut dicari', () {
      expect(ids(const JenisSampahQuery(search: 'logam').apply(all)), isEmpty);
    });
  });

  group('filter', () {
    test('satu kategori', () {
      expect(ids(const JenisSampahQuery(kategori: {'plastik'}).apply(all)),
          ['1', '4']);
    });

    test('kategori tanpa jenis memberi daftar kosong', () {
      expect(const JenisSampahQuery(kategori: {'kaca'}).apply(all), isEmpty);
    });

    test('beberapa kategori sekaligus', () {
      const q = JenisSampahQuery(kategori: {'plastik', 'logam'});
      expect(ids(q.apply(all)), ['3', '1', '4']);
    });

    test('digabung dengan cari', () {
      const q = JenisSampahQuery(kategori: {'plastik'}, search: 'gelas');
      expect(ids(q.apply(all)), ['4']);
    });
  });

  group('urut', () {
    test('nama Z-A', () {
      const q = JenisSampahQuery(ascending: false);
      expect(ids(q.apply(all)), ['5', '2', '4', '1', '3']);
    });

    test('harga termurah, nilai sama diurut nama lalu id', () {
      const q = JenisSampahQuery(sortField: JenisSampahSortField.harga);
      expect(ids(q.apply(all)), ['2', '1', '4', '5', '3']);
    });

    test('harga termahal', () {
      const q = JenisSampahQuery(
          sortField: JenisSampahSortField.harga, ascending: false);
      expect(ids(q.apply(all)), ['3', '5', '1', '4', '2']);
    });

    test('nama kembar diurut dengan id supaya stabil', () {
      final a = jenis('b', 'Kaleng', 1, 'logam');
      final b = jenis('a', 'Kaleng', 1, 'logam');
      expect(ids(const JenisSampahQuery().apply([a, b])), ['a', 'b']);
    });

    test('angka di dalam nama diurut sebagai angka', () {
      final l = [
        jenis('a', 'Botol 10 liter', 1, 'plastik'),
        jenis('b', 'Botol 2 liter', 1, 'plastik'),
        jenis('c', 'Botol 2', 1, 'plastik'),
        jenis('d', 'Botol 02 liter', 1, 'plastik'),
        jenis('e', 'Botol', 1, 'plastik'),
      ];
      // 2 dan 02 sama nilainya, jadi urutannya jatuh ke id (b sebelum d).
      expect(ids(const JenisSampahQuery().apply(l)), ['e', 'c', 'b', 'd', 'a']);
    });

    test('angka yang sangat panjang tidak meluap', () {
      final l = [
        jenis('a', 'X 99999999999999999999999', 1, 'dll'),
        jenis('b', 'X 9', 1, 'dll'),
      ];
      expect(ids(const JenisSampahQuery().apply(l)), ['b', 'a']);
    });

    test('tidak mengubah daftar asli', () {
      final src = [kardus, besi];
      const JenisSampahQuery().apply(src);
      expect(ids(src), ['2', '3']);
    });
  });

  group('isFiltering', () {
    test('cari atau kategori menyempitkan, urutan tidak', () {
      expect(const JenisSampahQuery().isFiltering, isFalse);
      expect(const JenisSampahQuery(ascending: false).isFiltering, isFalse);
      expect(const JenisSampahQuery(search: '  ').isFiltering, isFalse);
      expect(const JenisSampahQuery(search: 'a').isFiltering, isTrue);
      expect(const JenisSampahQuery(kategori: {'dll'}).isFiltering, isTrue);
    });
  });

  group('kategori tersedia', () {
    test('urut tetap, hanya yang ada di data, kosong dibuang', () {
      final cats = kategoriTersedia(
          [lain, botol, gelas, kardus, jenis('9', 'x', 1, '')]);
      expect(cats, ['kertas', 'plastik', 'dll']);
    });

    test('kategori tak dikenal ditaruh sebelum dll, urut abjad', () {
      expect(kategoriTersedia([lain, jenis('8', 'a', 1, 'organik'), botol]),
          ['plastik', 'organik', 'dll']);
    });
  });

  group('label kategori', () {
    test('dll menjadi Lainnya, lainnya diawali huruf besar', () {
      expect(labelKategori('dll'), 'Lainnya');
      expect(labelKategori('plastik'), 'Plastik');
      expect(labelKategori('organik'), 'Organik');
    });
  });

  group('copyWith', () {
    test('mengubah satu nilai, kategori bisa dikosongkan', () {
      const q = JenisSampahQuery(kategori: {'plastik'}, search: 'a');
      expect(q.copyWith(search: 'b').kategori, {'plastik'});
      expect(q.copyWith(kategori: null).kategori, isNull);
      expect(q.copyWith(ascending: false).ascending, isFalse);
      expect(q.copyWith(sortField: JenisSampahSortField.harga).sortField,
          JenisSampahSortField.harga);
    });

    test('kesetaraan nilai', () {
      expect(const JenisSampahQuery(search: 'a'),
          const JenisSampahQuery(search: 'a'));
      expect(const JenisSampahQuery(search: 'a').hashCode,
          const JenisSampahQuery(search: 'a').hashCode);
    });
  });
}
