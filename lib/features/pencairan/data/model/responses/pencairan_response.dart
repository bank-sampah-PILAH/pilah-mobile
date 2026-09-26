import 'package:freezed_annotation/freezed_annotation.dart';

part 'pencairan_response.freezed.dart';
part 'pencairan_response.g.dart';

/// `POST /api/v1/pencairan` and `GET /api/v1/pencairan/{id}`. Money fields are
/// DRF decimal strings such as `"265600.00"`.
@freezed
abstract class PencairanResponse with _$PencairanResponse {
  const factory PencairanResponse({
    required String id,
    @JsonKey(name: 'nasabah_id') @Default('') String nasabahId,
    @JsonKey(name: 'nasabah_nama') @Default('') String nasabahNama,
    @JsonKey(name: 'dicatat_oleh_nama') @Default('') String dicatatOlehNama,
    String? tanggal,
    required String nominal,
    required String metode,
    @Default('') String keterangan,
    @Default('tercatat') String status,
    @JsonKey(name: 'saldo_sebelum') required String saldoSebelum,
    @JsonKey(name: 'saldo_sesudah') required String saldoSesudah,
    @Default(false) bool diperbarui,
    @JsonKey(name: 'tanggal_edit_minimum') String? tanggalEditMinimum,
  }) = _PencairanResponse;

  factory PencairanResponse.fromJson(Map<String, dynamic> json) =>
      _$PencairanResponseFromJson(json);
}
