import 'package:freezed_annotation/freezed_annotation.dart';

import 'pencairan_response.dart';

part 'revisi_pencairan_response.freezed.dart';
part 'revisi_pencairan_response.g.dart';

/// One replaced version in `GET /api/v1/pencairan/{id}/riwayat`.
@freezed
abstract class RevisiPencairanResponse with _$RevisiPencairanResponse {
  const factory RevisiPencairanResponse({
    required int versi,
    String? tanggal,
    required String nominal,
    required String metode,
    @Default('') String keterangan,
    @JsonKey(name: 'saldo_sebelum') required String saldoSebelum,
    @JsonKey(name: 'saldo_sesudah') required String saldoSesudah,
    @Default('') String alasan,
    @JsonKey(name: 'diubah_oleh_nama') @Default('') String diubahOlehNama,
    @JsonKey(name: 'diubah_pada') String? diubahPada,
  }) = _RevisiPencairanResponse;

  factory RevisiPencairanResponse.fromJson(Map<String, dynamic> json) =>
      _$RevisiPencairanResponseFromJson(json);
}

@freezed
abstract class RiwayatRevisiPencairanResponse
    with _$RiwayatRevisiPencairanResponse {
  const factory RiwayatRevisiPencairanResponse({
    required PencairanResponse pencairan,
    @Default(<RevisiPencairanResponse>[]) List<RevisiPencairanResponse> revisi,
  }) = _RiwayatRevisiPencairanResponse;

  factory RiwayatRevisiPencairanResponse.fromJson(Map<String, dynamic> json) =>
      _$RiwayatRevisiPencairanResponseFromJson(json);
}
