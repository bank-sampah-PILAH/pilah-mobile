import 'package:equatable/equatable.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';

import '../../domain/model/draft_pencairan.dart';

/// One nasabah row in the editor, before it is saved.
class EditorItem extends Equatable {
  final String nasabahId;
  final String nasabahNama;

  /// The most that can be paid out: the saldo when the draft was started or
  /// last loaded. The server re-checks it against the live saldo.
  final int saldo;
  final int nominal;
  final MetodePencairan metode;

  /// Null follows the draft's general potongan.
  final Potongan? potongan;

  const EditorItem({
    required this.nasabahId,
    required this.nasabahNama,
    required this.saldo,
    required this.nominal,
    this.metode = MetodePencairan.tunai,
    this.potongan,
  });

  EditorItem copyWith({
    int? nominal,
    MetodePencairan? metode,
    Potongan? Function()? potongan,
  }) =>
      EditorItem(
        nasabahId: nasabahId,
        nasabahNama: nasabahNama,
        saldo: saldo,
        nominal: nominal ?? this.nominal,
        metode: metode ?? this.metode,
        potongan: potongan != null ? potongan() : this.potongan,
      );

  @override
  List<Object?> get props =>
      [nasabahId, nasabahNama, saldo, nominal, metode, potongan];
}

enum EditorPhase { idle, loading, saving, confirming, cancelling, exporting }

class DraftEditorState extends Equatable {
  /// Null until the draft has been saved for the first time.
  final String? draftId;
  final DraftStatus status;
  final String nama;
  final Potongan potonganDefault;

  /// What was last applied to everyone; the server keeps it with the draft.
  final JumlahUmum? jumlahUmum;
  final List<EditorItem> items;

  /// Who made and last changed the saved draft; blank before the first save.
  final String dibuatOlehNama;
  final String diubahOlehNama;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// True while the editor holds changes the server has not seen.
  final bool dirty;
  final EditorPhase phase;

  /// A server rejection of one item, keyed by nasabah id.
  final Map<String, String> itemErrors;

  /// Anything else that went wrong, for a notification.
  final String? errorMessage;

  const DraftEditorState({
    this.draftId,
    this.status = DraftStatus.draft,
    this.nama = '',
    this.potonganDefault = Potongan.nol,
    this.jumlahUmum,
    this.items = const [],
    this.dibuatOlehNama = '',
    this.diubahOlehNama = '',
    this.createdAt,
    this.updatedAt,
    this.dirty = false,
    this.phase = EditorPhase.idle,
    this.itemErrors = const {},
    this.errorMessage,
  });

  DraftEditorState copyWith({
    String? draftId,
    DraftStatus? status,
    String? nama,
    Potongan? potonganDefault,
    JumlahUmum? Function()? jumlahUmum,
    List<EditorItem>? items,
    String? dibuatOlehNama,
    String? diubahOlehNama,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? dirty,
    EditorPhase? phase,
    Map<String, String>? itemErrors,
    String? Function()? errorMessage,
  }) =>
      DraftEditorState(
        draftId: draftId ?? this.draftId,
        status: status ?? this.status,
        nama: nama ?? this.nama,
        potonganDefault: potonganDefault ?? this.potonganDefault,
        jumlahUmum: jumlahUmum != null ? jumlahUmum() : this.jumlahUmum,
        items: items ?? this.items,
        dibuatOlehNama: dibuatOlehNama ?? this.dibuatOlehNama,
        diubahOlehNama: diubahOlehNama ?? this.diubahOlehNama,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        dirty: dirty ?? this.dirty,
        phase: phase ?? this.phase,
        itemErrors: itemErrors ?? this.itemErrors,
        errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      );

  bool get isBusy => phase != EditorPhase.idle;

  /// The potongan that applies to [item] in rupiah, resolving the general one.
  int potonganEfektif(EditorItem item) =>
      (item.potongan ?? potonganDefault).hitung(item.nominal);

  int get totalNominal => items.fold(0, (sum, item) => sum + item.nominal);

  int get totalPotongan =>
      items.fold(0, (sum, item) => sum + potonganEfektif(item));

  int get totalDibayar => totalNominal - totalPotongan;

  /// True once the pengurus changed anything from the plain defaults.
  bool disesuaikan(EditorItem item) =>
      item.nominal != item.saldo || item.potongan != null;

  /// What the server said about [item], else what is wrong with it locally.
  String? errorFor(EditorItem item) =>
      itemErrors[item.nasabahId] ?? localError(item);

  /// What is wrong with [item], or null. Mirrors the backend's rules so the
  /// pengurus sees the problem before saving.
  String? localError(EditorItem item) {
    // A confirmed or cancelled draft is history: the saldo it spent is gone.
    if (status.terkunci) return null;
    if (item.nominal <= 0) return 'Nominal harus lebih dari nol';
    if (item.nominal > item.saldo) return 'Nominal melebihi saldo nasabah';
    final potongan = item.potongan ?? potonganDefault;
    if (potongan.jenis == PotonganJenis.persen && potongan.nilai > 100) {
      return 'Potongan persen maksimal 100';
    }
    if (potongan.nilai < 0) return 'Potongan tidak boleh negatif';
    if (potonganEfektif(item) > item.nominal) {
      return 'Potongan melebihi nominal';
    }
    return null;
  }

  /// Server rejections do not block a retry: the pengurus may have fixed the
  /// cause elsewhere (a top-up, a re-activation) and wants to try again.
  bool get canSave =>
      items.isNotEmpty && items.every((item) => localError(item) == null);

  /// A valid, still-open draft can be paid at any time. If it was never saved,
  /// or has unsaved edits, confirming saves it first.
  bool get canConfirm => !isBusy && status == DraftStatus.draft && canSave;

  /// A saved draft can always be exported as saved. One with edits, or never
  /// saved, is exported as it stands on screen, so it must be valid to be
  /// built: nothing is saved either way.
  bool get canExport =>
      !isBusy && items.isNotEmpty && ((draftId != null && !dirty) || canSave);

  @override
  List<Object?> get props => [
        draftId,
        status,
        nama,
        potonganDefault,
        jumlahUmum,
        items,
        dibuatOlehNama,
        diubahOlehNama,
        createdAt,
        updatedAt,
        dirty,
        phase,
        itemErrors,
        errorMessage,
      ];
}
