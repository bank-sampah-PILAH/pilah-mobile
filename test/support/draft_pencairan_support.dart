import 'package:dartz/dartz.dart';
import 'package:pilah_mobile/features/draft_pencairan/data/draft_pencairan_repository_impl.dart';
import 'package:pilah_mobile/features/draft_pencairan/data/remote/draft_pencairan_remote_data_source.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/draft_pencairan_interactor.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/use_cases/draft_pencairan_use_cases.dart';

import 'stub_api.dart';

/// The real draft pencairan use cases over the real data source, HTTP stubbed.
DraftPencairanUseCases buildDraftPencairanUseCases(StubApi api) =>
    DraftPencairanInteractor(DraftPencairanRepositoryImpl(
        DraftPencairanRemoteDataSourceImpl(api.network)));

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
}) =>
    {
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
