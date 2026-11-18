import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/features/draft_pencairan/data/draft_pencairan_repository_impl.dart';
import 'package:pilah_mobile/features/draft_pencairan/data/remote/draft_pencairan_remote_data_source.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/repository/draft_pencairan_repository.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/states/draft_editor_state.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/providers/draft_editor_provider.dart';

import 'stub_api.dart';

class TestDraftEditorNotifier extends DraftEditorNotifier {
  TestDraftEditorNotifier(
    super.repository, {
    DraftEditorState? initialState,
    List<dynamic> overrides = const [],
  }) : _initialState = initialState {
    container = ProviderContainer(
      overrides: [
        draftEditorProvider.overrideWith(() => this),
        ...overrides,
      ],
    );
    _subscription = container.listen(draftEditorProvider, (previous, next) {
      if (previous != null) _states.add(next);
    });
  }

  final DraftEditorState? _initialState;
  final _states = StreamController<DraftEditorState>.broadcast();
  late final ProviderContainer container;
  late final ProviderSubscription<DraftEditorState> _subscription;

  Stream<DraftEditorState> get stream => _states.stream;

  @override
  DraftEditorState build() => _initialState ?? super.build();

  void emit(DraftEditorState next) => state = next;

  Future<void> close() async {
    _subscription.close();
    container.dispose();
    await _states.close();
  }
}

/// The real draft pencairan repository over the real data source, HTTP stubbed.
DraftPencairanRepository buildDraftPencairanRepository(StubApi api) =>
    DraftPencairanRepositoryImpl(
        DraftPencairanRemoteDataSourceImpl(api.network));

const draftItemJson = {
  'id': 'i-1',
  'nasabah_id': 'n-1',
  'nasabah_nama': 'Ahmad Ridwan',
  'nominal': '100000.00',
  'metode': 'transfer',
  'potongan_jenis': '',
  'potongan_nilai': null,
  'potongan': '10000.00',
  'dibayar': '90000.00',
  'saldo_saat_ini': '465600.00',
};

Map<String, dynamic> draftJson({
  String status = 'draft',
  List<Map<String, dynamic>> items = const [draftItemJson],
  Map<String, dynamic> extra = const {},
}) =>
    {
      ...extra,
      'id': 'd-1',
      'nama': 'Cair Oktober',
      'status': status,
      'potongan_jenis': 'persen',
      'potongan_nilai': '10.00',
      'dibuat_oleh_nama': 'Ibu Sari',
      'diubah_oleh_nama': 'Pak Budi',
      'created_at': '2026-10-07T03:00:00Z',
      'updated_at': '2026-10-07T04:00:00Z',
      'items': items,
      'total_nominal': '100000.00',
      'total_potongan': '10000.00',
      'total_dibayar': '90000.00',
    };

/// Unwraps the side a test expects, failing loudly on the other one.
extension EitherSides<L, R> on Either<L, R> {
  R get right => fold((l) => throw StateError('Left: $l'), (r) => r);

  L get left => fold((l) => l, (r) => throw StateError('Right: $r'));
}
