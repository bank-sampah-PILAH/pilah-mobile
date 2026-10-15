import 'package:equatable/equatable.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';

import 'draft_editor_state.dart';

/// Which nasabah the editor list shows. Only the view: the draft itself, and
/// what is saved, always holds everyone.
enum ItemFilter {
  semua('Semua'),
  bermasalah('Bermasalah'),
  transfer('Transfer'),
  tunai('Tunai'),
  potonganKhusus('Potongan khusus'),
  pencairanKhusus('Pencairan khusus');

  final String label;

  const ItemFilter(this.label);
}

enum ItemSortField {
  dibayar('Dibayar'),
  nama('Nama'),
  saldo('Saldo awal'),
  potongan('Potongan');

  final String label;

  const ItemSortField(this.label);
}

/// A field and a direction. Names go A-Z first and amounts biggest first, which
/// is the way each is usually wanted; choosing the same field again flips it.
/// The list starts with the biggest dibayar, the amount that actually leaves.
class ItemSort extends Equatable {
  final ItemSortField field;
  final bool ascending;

  const ItemSort(this.field, this.ascending);

  const ItemSort.awal() : this(ItemSortField.dibayar, false);

  ItemSort pilih(ItemSortField pilihan) => pilihan == field
      ? ItemSort(field, !ascending)
      : ItemSort(pilihan, pilihan == ItemSortField.nama);

  @override
  List<Object?> get props => [field, ascending];
}

abstract final class EditorItemView {
  /// [state]'s items narrowed by [query] (part of a name) and [filter], in the
  /// order of [sort]. Ties fall back to name then id, so the order is stable.
  ///
  /// With [posisi] (from [urutan]) the order is that frozen ranking instead, so a
  /// card does not jump while its amount is typed; anyone missing from it goes
  /// last, by [sort].
  static List<EditorItem> tampilkan(
    DraftEditorState state, {
    String query = '',
    ItemFilter filter = ItemFilter.semua,
    ItemSort sort = const ItemSort.awal(),
    Map<String, int>? posisi,
  }) {
    final kata = query.trim().toLowerCase();
    final hasil = state.items.where((item) {
      if (kata.isNotEmpty && !item.nasabahNama.toLowerCase().contains(kata)) {
        return false;
      }
      return _cocok(state, item, filter);
    }).toList();
    hasil.sort((a, b) {
      if (posisi != null) {
        final urutA = posisi[a.nasabahId];
        final urutB = posisi[b.nasabahId];
        if (urutA != null && urutB != null) return urutA.compareTo(urutB);
        if (urutA != null) return -1;
        if (urutB != null) return 1;
      }
      return _bandingkan(state, a, b, sort);
    });
    return hasil;
  }

  /// Everyone's place in the order of [sort], to keep while amounts change.
  static Map<String, int> urutan(DraftEditorState state, ItemSort sort) {
    final urut = tampilkan(state, sort: sort);
    return {for (var i = 0; i < urut.length; i++) urut[i].nasabahId: i};
  }

  /// How many of [state]'s nasabah [filter] holds, whatever is searched.
  static int hitung(DraftEditorState state, ItemFilter filter) =>
      state.items.where((item) => _cocok(state, item, filter)).length;

  static bool _cocok(DraftEditorState state, EditorItem item, ItemFilter f) {
    switch (f) {
      case ItemFilter.semua:
        return true;
      case ItemFilter.bermasalah:
        return state.errorFor(item) != null;
      case ItemFilter.potonganKhusus:
        return item.potongan != null;
      case ItemFilter.pencairanKhusus:
        // The default is the whole saldo; anything else was chosen by hand.
        return item.nominal != item.saldo;
      case ItemFilter.transfer:
        return item.metode == MetodePencairan.transfer;
      case ItemFilter.tunai:
        return item.metode == MetodePencairan.tunai;
    }
  }

  static int _bandingkan(
    DraftEditorState state,
    EditorItem a,
    EditorItem b,
    ItemSort sort,
  ) {
    int utama;
    switch (sort.field) {
      case ItemSortField.nama:
        utama = _nama(a).compareTo(_nama(b));
      case ItemSortField.dibayar:
        utama = _dibayar(state, a).compareTo(_dibayar(state, b));
      case ItemSortField.potongan:
        utama = state.potonganEfektif(a).compareTo(state.potonganEfektif(b));
      case ItemSortField.saldo:
        utama = a.saldo.compareTo(b.saldo);
    }
    if (!sort.ascending) utama = -utama;
    if (utama != 0) return utama;
    final nama = _nama(a).compareTo(_nama(b));
    return nama != 0 ? nama : a.nasabahId.compareTo(b.nasabahId);
  }

  static String _nama(EditorItem item) => item.nasabahNama.toLowerCase();

  static int _dibayar(DraftEditorState state, EditorItem item) =>
      item.nominal - state.potonganEfektif(item);
}
