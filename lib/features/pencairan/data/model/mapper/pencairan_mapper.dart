import '../responses/pencairan_response.dart';
import '../../../domain/model/pencairan.dart';

class PencairanMapper {
  static Pencairan mapResponseToDomain(PencairanResponse response) {
    return Pencairan(
      id: response.id,
      nasabahNama: response.nasabahNama,
      nominal: rupiah(response.nominal),
      metode: MetodePencairan.fromApi(response.metode),
      tanggal: DateTime.tryParse(response.tanggal ?? '')?.toLocal(),
      keterangan: response.keterangan,
      status: response.status,
      saldoSebelum: rupiah(response.saldoSebelum),
      saldoSesudah: rupiah(response.saldoSesudah),
    );
  }

  /// Decimal string to whole rupiah, rounded down: sen are never paid out,
  /// matching the backend's money rule.
  static int rupiah(Object? value) =>
      (double.tryParse(value?.toString() ?? '') ?? 0).floor();
}
