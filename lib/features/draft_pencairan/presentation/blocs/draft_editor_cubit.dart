import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';

import '../../domain/model/draft_pencairan.dart';
import '../../domain/repository/draft_pencairan_repository.dart';
import 'draft_editor_state.dart';

const _tidakMemenuhiSyarat =
    'Nasabah ini sudah tidak memenuhi syarat. Hapus dari draft untuk melanjutkan.';

/// Holds a draft pencairan while the pengurus shapes it: who is paid, how
/// much, how, and what potongan comes off. Nothing reaches the server until
/// it is saved, and the saldo never moves until the payment is confirmed.
@injectable
class DraftEditorCubit extends Cubit<DraftEditorState> {
  final DraftPencairanRepository _repository;

  DraftEditorCubit(this._repository) : super(const DraftEditorState());

  /// Starts a draft for [kandidat]: each is paid their whole saldo, in cash.
  void startNew(List<Kandidat> kandidat) {
    emit(DraftEditorState(
      items: [
        for (final k in kandidat)
          EditorItem(
            nasabahId: k.id,
            nasabahNama: k.nama,
            saldo: k.saldo,
            nominal: k.saldo,
          ),
      ],
    ));
  }

  void setNama(String nama) => _change(state.copyWith(nama: nama));

  void setPotonganDefault(Potongan potongan) =>
      _change(state.copyWith(potonganDefault: potongan));

  void setMetodeSemua(MetodePencairan metode) => _change(
        state.copyWith(
          items: [
            for (final item in state.items) item.copyWith(metode: metode)
          ],
          metodeUmum: metode,
        ),
        touched: state.items.map((item) => item.nasabahId).toSet(),
      );

  /// Applies the general settings together, in one edit. Only what is given
  /// changes: [metode] and [jumlah] rewrite every item; [potongan] becomes the
  /// draft's default, which items with their own potongan do not follow.
  void terapkanUmum({
    MetodePencairan? metode,
    JumlahUmum? jumlah,
    Potongan? potongan,
  }) {
    if (metode == null && jumlah == null && potongan == null) return;
    final berubah = metode != null || jumlah != null;
    _change(
      state.copyWith(
        items: [
          for (final item in state.items)
            item.copyWith(
              metode: metode,
              nominal: jumlah?.hitung(item.saldo),
            ),
        ],
        potonganDefault: potongan,
      ),
      touched: berubah ? state.items.map((item) => item.nasabahId).toSet() : {},
    );
  }

  void setItemMetode(String nasabahId, MetodePencairan metode) =>
      _editItem(nasabahId, (item) => item.copyWith(metode: metode));

  void setItemNominal(String nasabahId, int nominal) =>
      _editItem(nasabahId, (item) => item.copyWith(nominal: nominal));

  /// Gives the item its own potongan, or null to follow the general one.
  void setItemPotongan(String nasabahId, Potongan? potongan) =>
      _editItem(nasabahId, (item) => item.copyWith(potongan: () => potongan));

  /// Back to the plain defaults: the whole saldo, cash and the general potongan.
  void resetItem(String nasabahId) => _editItem(
        nasabahId,
        (item) => item.copyWith(
          nominal: item.saldo,
          metode: state.metodeUmum,
          potongan: () => null,
        ),
      );

  void removeItem(String nasabahId) => _change(state.copyWith(
        items: [
          for (final item in state.items)
            if (item.nasabahId != nasabahId) item,
        ],
        itemErrors: {...state.itemErrors}..remove(nasabahId),
      ));

  /// Loads a saved draft to resume it. Each item's ceiling is the nasabah's
  /// saldo now, so a nominal the saldo no longer covers shows up as an error.
  Future<void> load(String id) async {
    if (state.isBusy) return;
    emit(state.copyWith(phase: EditorPhase.loading, errorMessage: () => null));
    final result = await _repository.getDraft(id);
    result.fold(
      (failure) => emit(state.copyWith(
        phase: EditorPhase.idle,
        errorMessage: () => failure.displayMessage,
      )),
      (draft) => emit(_fromServer(draft)),
    );
  }

  /// Creates the draft, or updates it once it exists. The server answers with
  /// the calculated draft, which replaces what the editor held.
  Future<void> save() async {
    if (state.isBusy || !state.canSave) return;
    emit(state.copyWith(phase: EditorPhase.saving, errorMessage: () => null));
    final input = _input();
    final id = state.draftId;
    final result = id == null
        ? await _repository.createDraft(input)
        : await _repository.updateDraft(id, input);
    result.fold(
      (failure) => emit(_rejected(failure)),
      (draft) => emit(_fromServer(draft)),
    );
  }

  /// Records that the pengurus has paid: the saldo and riwayat change, once.
  Future<void> confirm() async {
    final id = state.draftId;
    if (id == null || !state.canConfirm) return;
    await _transition(EditorPhase.confirming, _useCases.confirmDraft(id));
  }

  /// Drops a draft that has not been paid. The saldo was never touched.
  Future<void> cancel() async {
    final id = state.draftId;
    if (id == null || state.isBusy || state.status.terkunci) return;
    await _transition(EditorPhase.cancelling, _repository.cancelDraft(id));
  }

  Future<void> _transition(
    EditorPhase phase,
    Future<Either<NetworkException, DraftPencairan>> call,
  ) async {
    emit(state.copyWith(phase: phase, errorMessage: () => null));
    final result = await call;
    result.fold(
      (failure) => emit(_rejected(failure)),
      (draft) => emit(_fromServer(draft)),
    );
  }

  DraftInput _input() => DraftInput(
        nama: state.nama,
        potonganDefault: state.potonganDefault,
        items: [
          for (final item in state.items)
            DraftItemInput(
              nasabahId: item.nasabahId,
              nominal: item.nominal,
              metode: item.metode,
              potongan: item.potongan,
            ),
        ],
      );

  /// An `items[i].field` rejection lands on the i-th item as sent; anything
  /// else becomes a message.
  DraftEditorState _rejected(NetworkException failure) {
    final errors = <String, String>{};
    failure.fieldErrors().forEach((key, message) {
      final match = RegExp(r'^items\[(\d+)\]\.(\w+)').firstMatch(key);
      final index = int.tryParse(match?.group(1) ?? '');
      if (index != null && index < state.items.length) {
        errors[state.items[index].nasabahId] =
            match!.group(2) == 'nasabah_id' ? _tidakMemenuhiSyarat : message;
      }
    });
    return state.copyWith(
      phase: EditorPhase.idle,
      itemErrors: errors,
      errorMessage: () => errors.isEmpty ? failure.displayMessage : null,
    );
  }

  /// The method most nasabah are on, taken as the one chosen for everyone; on
  /// a tie the editor keeps what it already had.
  MetodePencairan _metodeUmum(DraftPencairan draft) {
    final transfer =
        draft.items.where((i) => i.metode == MetodePencairan.transfer).length;
    final tunai = draft.items.length - transfer;
    if (transfer == tunai) return state.metodeUmum;
    return transfer > tunai ? MetodePencairan.transfer : MetodePencairan.tunai;
  }

  DraftEditorState _fromServer(DraftPencairan draft) => DraftEditorState(
        metodeUmum: _metodeUmum(draft),
        draftId: draft.id,
        status: draft.status,
        nama: draft.nama,
        potonganDefault: draft.potonganDefault,
        dibuatOlehNama: draft.dibuatOlehNama,
        diubahOlehNama: draft.diubahOlehNama,
        createdAt: draft.createdAt,
        updatedAt: draft.updatedAt,
        items: [
          for (final item in draft.items)
            EditorItem(
              nasabahId: item.nasabahId,
              nasabahNama: item.nasabahNama,
              saldo: item.saldoSaatIni,
              nominal: item.nominal,
              metode: item.metode,
              potongan: item.potongan,
            ),
        ],
      );

  /// Applies an edit: it makes the editor dirty, and a changed item no longer
  /// carries the server's complaint about its old values.
  void _change(DraftEditorState next, {Set<String> touched = const {}}) {
    if (state.status.terkunci || state.isBusy) return;
    emit(next.copyWith(
      dirty: true,
      itemErrors: {
        for (final entry in next.itemErrors.entries)
          if (!touched.contains(entry.key)) entry.key: entry.value,
      },
    ));
  }

  void _editItem(String nasabahId, EditorItem Function(EditorItem) change) =>
      _change(
        state.copyWith(items: [
          for (final item in state.items)
            item.nasabahId == nasabahId ? change(item) : item,
        ]),
        touched: {nasabahId},
      );
}
