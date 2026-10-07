import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';

import '../../domain/model/draft_pencairan.dart';
import '../../domain/use_cases/draft_pencairan_use_cases.dart';
import 'draft_editor_state.dart';

/// Holds a draft pencairan while the pengurus shapes it: who is paid, how
/// much, how, and what potongan comes off. Nothing reaches the server until
/// it is saved, and the saldo never moves until the payment is confirmed.
@injectable
class DraftEditorCubit extends Cubit<DraftEditorState> {
  final DraftPencairanUseCases _useCases;

  DraftEditorCubit(this._useCases) : super(const DraftEditorState());

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

  void setMetodeSemua(MetodePencairan metode) => _editAll(
        (item) => item.copyWith(metode: metode),
      );

  void setItemMetode(String nasabahId, MetodePencairan metode) =>
      _editItem(nasabahId, (item) => item.copyWith(metode: metode));

  void setItemNominal(String nasabahId, int nominal) =>
      _editItem(nasabahId, (item) => item.copyWith(nominal: nominal));

  /// Gives the item its own potongan, or null to follow the general one.
  void setItemPotongan(String nasabahId, Potongan? potongan) =>
      _editItem(nasabahId, (item) => item.copyWith(potongan: () => potongan));

  /// Back to the plain defaults: the whole saldo and the general potongan.
  void resetItem(String nasabahId) => _editItem(
        nasabahId,
        (item) => item.copyWith(nominal: item.saldo, potongan: () => null),
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
    final result = await _useCases.getDraft(id);
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
        ? await _useCases.createDraft(input)
        : await _useCases.updateDraft(id, input);
    result.fold(
      (failure) => emit(_rejected(failure)),
      (draft) => emit(_fromServer(draft)),
    );
  }

  /// Drops a draft that has not been paid. The saldo was never touched.
  Future<void> cancel() async {
    final id = state.draftId;
    if (id == null || state.isBusy || state.status.terkunci) return;
    await _transition(EditorPhase.cancelling, _useCases.cancelDraft(id));
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
      final index = int.tryParse(
          RegExp(r'^items\[(\d+)\]').firstMatch(key)?.group(1) ?? '');
      if (index != null && index < state.items.length) {
        errors[state.items[index].nasabahId] = message;
      }
    });
    return state.copyWith(
      phase: EditorPhase.idle,
      itemErrors: errors,
      errorMessage: () => errors.isEmpty ? failure.displayMessage : null,
    );
  }

  DraftEditorState _fromServer(DraftPencairan draft) => DraftEditorState(
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

  void _editAll(EditorItem Function(EditorItem) change) => _change(
        state.copyWith(items: state.items.map(change).toList()),
        touched: state.items.map((item) => item.nasabahId).toSet(),
      );

  void _editItem(String nasabahId, EditorItem Function(EditorItem) change) =>
      _change(
        state.copyWith(items: [
          for (final item in state.items)
            item.nasabahId == nasabahId ? change(item) : item,
        ]),
        touched: {nasabahId},
      );
}
