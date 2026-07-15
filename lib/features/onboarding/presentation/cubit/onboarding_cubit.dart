import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/api_call.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/onboarding/data/datasources/onboarding_remote_data_source.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/features/onboarding/presentation/cubit/onboarding_state.dart';

@lazySingleton
class OnboardingCubit extends Cubit<OnboardingState> {
  final OnboardingRemoteDataSource _dataSource;

  OnboardingCubit(this._dataSource) : super(const OnboardingInitial());

  /// Submits the profile-completion form. On success returns the backend
  /// [OnboardingResult] (with the next routing step); otherwise the
  /// [NetworkException] so the screen can surface validation errors.
  Future<({OnboardingResult? result, NetworkException? error})> completeProfile(
    CompleteProfileRequest request,
  ) async {
    emit(const OnboardingSubmitting());
    final either = await apiCall<OnboardingResult>(
      func: _dataSource.completeProfile(request),
      mapper: (value) => value as OnboardingResult,
    );
    emit(const OnboardingInitial());
    return either.fold(
      (error) => (result: null, error: error),
      (result) => (result: result, error: null),
    );
  }

  /// Joins an existing bank sampah with an invite [token]. Returns the backend
  /// [OnboardingResult] (with the next routing step) on success; otherwise the
  /// [NetworkException] carrying the backend's reason (invalid/expired token,
  /// or a bank sampah that is not approved yet).
  Future<({OnboardingResult? result, NetworkException? error})> acceptInvite(
    String token,
  ) async {
    emit(const OnboardingSubmitting());
    final either = await apiCall<OnboardingResult>(
      func: _dataSource.acceptInvite(token),
      mapper: (value) => value as OnboardingResult,
    );
    emit(const OnboardingInitial());
    return either.fold(
      (error) => (result: null, error: error),
      (result) => (result: result, error: null),
    );
  }

  /// Submits the bank-sampah registration (multipart, with `foto_kegiatan`).
  Future<({OnboardingResult? result, NetworkException? error})>
      registerBankSampah(RegisterBankSampahRequest request) async {
    emit(const OnboardingSubmitting());
    final either = await apiCall<OnboardingResult>(
      func: _dataSource.registerBankSampah(request),
      mapper: (value) => value as OnboardingResult,
    );
    emit(const OnboardingInitial());
    return either.fold(
      (error) => (result: null, error: error),
      (result) => (result: result, error: null),
    );
  }
}
