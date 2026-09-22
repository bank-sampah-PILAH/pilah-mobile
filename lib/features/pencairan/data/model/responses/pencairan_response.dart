import 'package:freezed_annotation/freezed_annotation.dart';

part 'pencairan_response.freezed.dart';
part 'pencairan_response.g.dart';

@freezed
abstract class PencairanResponse with _$PencairanResponse {
  const factory PencairanResponse({
    required int id,
  }) = _PencairanResponse;

  factory PencairanResponse.fromJson(Map<String, dynamic> json) =>
      _$PencairanResponseFromJson(json);
}
