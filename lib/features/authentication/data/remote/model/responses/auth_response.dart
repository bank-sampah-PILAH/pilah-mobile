import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_response.freezed.dart';
part 'auth_response.g.dart';

@freezed
abstract class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
    @JsonKey(name: 'token_type') String? tokenType,
    @JsonKey(name: 'expires_in') int? expiresIn,
    required UserResponse user,
    @JsonKey(name: 'next_step') String? nextStep,
    @JsonKey(name: 'is_new_user') bool? isNewUser,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
}

@freezed
abstract class UserResponse with _$UserResponse {
  const factory UserResponse({
    required String id,
    required String name,
    required String nama,
    required String email,
    required String role,
    @JsonKey(name: 'bank_sampah_id') String? bankSampahId,
    @JsonKey(name: 'bank_sampah_nama') String? bankSampahNama,
    @JsonKey(name: 'bank_sampah_status') String? bankSampahStatus,
    @JsonKey(name: 'is_profile_complete') bool? isProfileComplete,
    @JsonKey(name: 'is_primary_pengelola') bool? isPrimaryPengelola,
    String? state,
  }) = _UserResponse;

  factory UserResponse.fromJson(Map<String, dynamic> json) =>
      _$UserResponseFromJson(json);
}
