import '../responses/pencairan_response.dart';
import '../responses/revisi_pencairan_response.dart';
import '../../../domain/model/pencairan.dart';
import '../../../domain/model/revisi_pencairan.dart';

class PencairanMapper {
  static Pencairan mapResponseToDomain(PencairanResponse response) {
    return Pencairan(
      id: response.id,
      nasabahId: response.nasabahId,
      nasabahNama: response.nasabahNama,
      dicatatOlehNama: response.dicatatOlehNama,
      nominal: rupiah(response.nominal),
      metode: MetodePencairan.fromApi(response.metode),
      tanggal: DateTime.tryParse(response.tanggal ?? '')?.toLocal(),
      keterangan: response.keterangan,
      status: response.status,
      saldoSebelum: rupiah(response.saldoSebelum),
      saldoSesudah: rupiah(response.saldoSesudah),
      diperbarui: response.diperbarui,
      tanggalEditMinimum:
          DateTime.tryParse(response.tanggalEditMinimum ?? '')?.toLocal(),
    );
  }

  static RiwayatRevisiPencairan mapRiwayatRevisiToDomain(
    RiwayatRevisiPencairanResponse response,
  ) {
    return RiwayatRevisiPencairan(
      pencairan: mapResponseToDomain(response.pencairan),
      revisi: response.revisi
          .map(
            (row) => RevisiPencairan(
              versi: row.versi,
              tanggal: DateTime.tryParse(row.tanggal ?? '')?.toLocal(),
              nominal: rupiah(row.nominal),
              metode: MetodePencairan.fromApi(row.metode),
              keterangan: row.keterangan,
              saldoSebelum: rupiah(row.saldoSebelum),
              saldoSesudah: rupiah(row.saldoSesudah),
              alasan: row.alasan,
              diubahOlehNama: row.diubahOlehNama,
              diubahPada: DateTime.tryParse(row.diubahPada ?? '')?.toLocal(),
            ),
          )
          .toList(),
    );
  }

  /// Decimal string to whole rupiah, rounded down: sen are never paid out,
  /// matching the backend's money rule.
  static int rupiah(Object? value) =>
      (double.tryParse(value?.toString() ?? '') ?? 0).floor();
}
