import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/model/draft_pencairan.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/blocs/draft_editor_state.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/blocs/editor_item_view.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';

EditorItem _item(
  String id,
  String nama, {
  int saldo = 100000,
  int? nominal,
  MetodePencairan metode = MetodePencairan.tunai,
  Potongan? potongan,
}) =>
    EditorItem(
      nasabahId: id,
      nasabahNama: nama,
      saldo: saldo,
      nominal: nominal ?? saldo,
      metode: metode,
      potongan: potongan,
    );

DraftEditorState _state(List<EditorItem> items,
        {Potongan potonganDefault = Potongan.nol,
        DraftStatus status = DraftStatus.draft}) =>
    DraftEditorState(
        items: items, potonganDefault: potonganDefault, status: status);

List<String> _ids(List<EditorItem> items) =>
    items.map((i) => i.nasabahId).toList();

void main() {
  final ahmad = _item('a', 'Ahmad Ridwan', saldo: 465600);
  final budi = _item('b', 'budi santoso',
      saldo: 50000, metode: MetodePencairan.transfer);
  final citra = _item('c', 'Citra Dewi',
      saldo: 250000, potongan: const Potongan(PotonganJenis.persen, 10));
  final dedi = _item('d', 'Dedi Salah', saldo: 80000, nominal: 90000);
  final state = _state([citra, dedi, ahmad, budi]);

  List<String> lihat({
    String query = '',
    ItemFilter filter = ItemFilter.semua,
    ItemSort sort = const ItemSort.awal(),
  }) =>
      _ids(EditorItemView.tampilkan(state,
          query: query, filter: filter, sort: sort));

  group('search', () {
    test('matches part of a name, ignoring case', () {
      expect(lihat(query: 'BUDI'), ['b']);
      expect(lihat(query: 'dew'), ['c']);
      expect(lihat(query: 'sa'), ['d', 'b'], reason: 'biggest dibayar first');
    });

    test('ignores surrounding spaces and an empty query shows everyone', () {
      expect(lihat(query: '  ahmad '), ['a']);
      expect(lihat(query: '   '), hasLength(4));
    });

    test('says nothing found as an empty list', () {
      expect(lihat(query: 'zzz'), isEmpty);
    });
  });

  group('filter', () {
    test('Bermasalah keeps those the editor would refuse to save', () {
      expect(lihat(filter: ItemFilter.bermasalah), ['d']);
    });

    test('Potongan khusus keeps those with their own potongan', () {
      expect(lihat(filter: ItemFilter.potonganKhusus), ['c']);
    });

    test('Pencairan khusus keeps those not paid out in full', () {
      final edi = _item('e', 'Edi Sebagian', saldo: 60000, nominal: 20000);
      final campur = _state([ahmad, budi, edi]);

      expect(
        _ids(EditorItemView.tampilkan(campur,
            filter: ItemFilter.pencairanKhusus)),
        ['e'],
      );
      expect(EditorItemView.hitung(campur, ItemFilter.pencairanKhusus), 1);
      expect(EditorItemView.hitung(state, ItemFilter.pencairanKhusus), 1,
          reason: 'Dedi asks for more than his saldo, which is not the whole');
    });

    test('Transfer and Tunai split by method', () {
      expect(lihat(filter: ItemFilter.transfer), ['b']);
      expect(lihat(filter: ItemFilter.tunai), ['a', 'c', 'd']);
    });

    test('a filter and a search work together', () {
      expect(lihat(filter: ItemFilter.tunai, query: 'dewi'), ['c']);
      expect(lihat(filter: ItemFilter.transfer, query: 'ahmad'), isEmpty);
    });

    test('counts ignore the search, so a chip says how many it holds', () {
      expect(EditorItemView.hitung(state, ItemFilter.semua), 4);
      expect(EditorItemView.hitung(state, ItemFilter.bermasalah), 1);
      expect(EditorItemView.hitung(state, ItemFilter.potonganKhusus), 1);
      expect(EditorItemView.hitung(state, ItemFilter.transfer), 1);
      expect(EditorItemView.hitung(state, ItemFilter.tunai), 3);
    });

    test('a paid or cancelled draft has no problems left to fix', () {
      final selesai = _state([dedi], status: DraftStatus.dikonfirmasi);

      expect(EditorItemView.hitung(selesai, ItemFilter.bermasalah), 0);
    });

    test('a server rejection counts as a problem too', () {
      final ditolak = state.copyWith(itemErrors: {'a': 'Nasabah tidak aktif'});

      expect(
        _ids(EditorItemView.tampilkan(ditolak, filter: ItemFilter.bermasalah)),
        ['a', 'd'],
      );
    });
  });

  group('sort', () {
    test('starts with the biggest dibayar first', () {
      // dibayar: a 465600, c 225000, d 90000, b 50000
      expect(lihat(), ['a', 'c', 'd', 'b']);
    });

    test('tapping the same field again reverses it', () {
      expect(lihat(sort: const ItemSort.awal().pilih(ItemSortField.dibayar)),
          ['b', 'd', 'c', 'a']);
    });

    test('names go A-Z first, ignoring case, then Z-A', () {
      final az = const ItemSort.awal().pilih(ItemSortField.nama);

      expect(lihat(sort: az), ['a', 'b', 'c', 'd']);
      expect(lihat(sort: az.pilih(ItemSortField.nama)), ['d', 'c', 'b', 'a']);
    });

    test('saldo awal starts with the biggest first', () {
      expect(lihat(sort: const ItemSort.awal().pilih(ItemSortField.saldo)),
          ['a', 'c', 'd', 'b']);
    });

    test('potongan sorts by the amount, the general one included', () {
      final umum = _state([ahmad, budi, citra],
          potonganDefault: const Potongan(PotonganJenis.rupiah, 5000));
      // a and b follow the general 5000; c has 10% of 250000 = 25000.
      final urut = EditorItemView.tampilkan(umum,
          sort: const ItemSort.awal().pilih(ItemSortField.potongan));

      expect(_ids(urut), ['c', 'a', 'b']);
    });

    test('ties fall back to name, so the order never jitters', () {
      final sama = _state([_item('2', 'Zaki'), _item('1', 'Adi')]);

      expect(
        _ids(EditorItemView.tampilkan(sama)),
        ['1', '2'],
      );
    });

    test('choosing a new field starts in its natural direction', () {
      final nama = const ItemSort.awal().pilih(ItemSortField.nama);
      final saldo = nama.pilih(ItemSortField.saldo);

      expect(nama.ascending, isTrue);
      expect(saldo.field, ItemSortField.saldo);
      expect(saldo.ascending, isFalse);
    });

    test('the fields are listed dibayar, nama, saldo awal, potongan', () {
      expect(ItemSortField.values.map((f) => f.label),
          ['Dibayar', 'Nama', 'Saldo awal', 'Potongan']);
    });
  });

  group('a frozen order', () {
    test('follows the given positions, not the live amounts', () {
      // By dibayar it would be a, c, d, b; the frozen order says otherwise.
      final posisi = {'b': 0, 'd': 1, 'c': 2, 'a': 3};

      expect(
        _ids(EditorItemView.tampilkan(state, posisi: posisi)),
        ['b', 'd', 'c', 'a'],
      );
    });

    test('still narrows by search and filter', () {
      final posisi = {'b': 0, 'd': 1, 'c': 2, 'a': 3};

      expect(
        _ids(EditorItemView.tampilkan(state,
            posisi: posisi, filter: ItemFilter.tunai)),
        ['d', 'c', 'a'],
      );
    });

    test('puts anyone without a position last, by the live sort', () {
      final posisi = {'b': 0};

      expect(_ids(EditorItemView.tampilkan(state, posisi: posisi)),
          ['b', 'a', 'c', 'd']);
    });

    test('urutan() ranks everyone by the sort', () {
      expect(EditorItemView.urutan(state, const ItemSort.awal()),
          {'a': 0, 'c': 1, 'd': 2, 'b': 3});
    });
  });

  test('the view never changes what is saved', () {
    final salinan = List<EditorItem>.of(state.items);

    EditorItemView.tampilkan(state,
        query: 'a', sort: const ItemSort.awal().pilih(ItemSortField.saldo));

    expect(state.items, salinan);
  });
}
