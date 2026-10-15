import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/revisi_pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/riwayat_pencairan_filter.dart';
import 'package:pilah_mobile/features/pencairan/domain/pencairan_interactor.dart';
import 'package:pilah_mobile/features/pencairan/domain/repository/pencairan_repository.dart';

class _MockRepository extends Mock implements PencairanRepository {}

const _record = Pencairan(
  id: 'p-1',
  nasabahNama: 'Ayu',
  nominal: 150000,
  metode: MetodePencairan.transfer,
  tanggal: null,
  keterangan: '',
  status: 'tercatat',
  saldoSebelum: 200000,
  saldoSesudah: 50000,
);

final _request = PencairanRequest(
  nasabahId: 'n-1',
  nominal: 150000,
  metode: MetodePencairan.transfer,
  tanggal: DateTime(2026, 9, 22),
);

final _editRequest = EditPencairanRequest(
  id: 'p-1',
  nominal: 125000,
  metode: MetodePencairan.tunai,
  tanggal: DateTime(2026, 9, 22),
  keterangan: 'Diambil',
  alasan: 'Salah catat',
);

final _revisi = RiwayatRevisiPencairan(pencairan: _record, revisi: []);

void main() {
  late _MockRepository repository;
  late PencairanInteractor interactor;

  setUp(() {
    repository = _MockRepository();
    interactor = PencairanInteractor(repository);
  });

  test('delegates saldo lookup', () async {
    const expected = Right<NetworkException, int>(50000);
    when(() => repository.getSaldo('n-1')).thenAnswer((_) async => expected);

    expect(await interactor.getSaldo('n-1'), expected);
    verify(() => repository.getSaldo('n-1')).called(1);
  });

  test('delegates payout creation', () async {
    const expected = Right<NetworkException, Pencairan>(_record);
    when(() => repository.createPencairan(_request))
        .thenAnswer((_) async => expected);

    expect(await interactor.createPencairan(_request), expected);
    verify(() => repository.createPencairan(_request)).called(1);
  });

  test('delegates payout history lookup', () async {
    const filter = RiwayatPencairanFilter(periode: RiwayatPeriode.semua);
    const expected = Right<NetworkException, List<Pencairan>>([_record]);
    when(() => repository.getRiwayat(filter)).thenAnswer((_) async => expected);

    expect(await interactor.getRiwayat(filter), expected);
    verify(() => repository.getRiwayat(filter)).called(1);
  });

  test('delegates payout edit', () async {
    const expected = Right<NetworkException, Pencairan>(_record);
    when(() => repository.editPencairan(_editRequest))
        .thenAnswer((_) async => expected);

    expect(await interactor.editPencairan(_editRequest), expected);
    verify(() => repository.editPencairan(_editRequest)).called(1);
  });

  test('delegates payout revision history lookup', () async {
    final expected = Right<NetworkException, RiwayatRevisiPencairan>(_revisi);
    when(() => repository.getRevisi('p-1')).thenAnswer((_) async => expected);

    expect(await interactor.getRevisi('p-1'), expected);
    verify(() => repository.getRevisi('p-1')).called(1);
  });
}
