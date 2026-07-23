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

  /// Profile input captured on step one of the registration wizard and not sent
  /// anywhere yet.
  ///
  /// Held on the cubit rather than in [OnboardingState] on purpose. The states
  /// are transient signals — every call here ends with `emit(OnboardingInitial())`
  /// — so a draft carried in them would have to be threaded through each emit
  /// by hand, and the one that forgot would silently empty the user's form.
  /// This is a lazySingleton, so the field outlives both screens.
  CompleteProfileRequest? _profileDraft;

  /// Whether [_profileDraft] has already been accepted by the backend.
  ///
  /// `PUT /onboarding/profile` refuses a second call outright — services.py
  /// raises "Profil sudah lengkap" once `is_profile_complete` is set — so when
  /// the profile lands and the bank sampah registration behind it fails, the
  /// retry must not replay step one. Without this the first failure would be
  /// permanent: every retry would die on the profile call the user already
  /// succeeded at.
  bool _profileSubmitted = false;

  /// The draft to prefill step one with, or null when there is nothing pending.
  CompleteProfileRequest? get profileDraft => _profileDraft;

  /// Whether the wizard is mid-flight, i.e. the user reached the registration
  /// form through step one rather than landing on it directly.
  bool get hasProfileDraft => _profileDraft != null;

  /// Banks step one's input and moves on without touching the network.
  void saveProfileDraft(CompleteProfileRequest request) {
    _profileDraft = request;
  }

  /// Forgets the pending draft. Called once the whole wizard has landed, and on
  /// logout, so a later session never resubmits a stranger's half-filled form.
  void clearProfileDraft() {
    _profileDraft = null;
    _profileSubmitted = false;
  }

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

  /// Sends the whole wizard: the banked profile draft first, then the bank
  /// sampah registration, and reports the step that failed.
  ///
  /// The two calls are ordered, not atomic — there is no endpoint that takes
  /// both, and the backend derives `next_step` from the profile being complete,
  /// so the profile has to land first for the registration's answer to be
  /// accurate. What that costs is a window where step one has committed and step
  /// two has not, which is exactly the state [_profileSubmitted] exists to
  /// survive: the user retries, only the registration is re-sent, and the
  /// profile call that would now fail is never made.
  ///
  /// With no draft banked this is just [registerBankSampah] — the user reached
  /// the form directly, on an account whose profile was already complete.
  Future<({OnboardingResult? result, NetworkException? error})>
      submitRegistration(RegisterBankSampahRequest request) async {
    emit(const OnboardingSubmitting());

    final draft = _profileDraft;
    if (draft != null && !_profileSubmitted) {
      final profileEither = await apiCall<OnboardingResult>(
        func: _dataSource.completeProfile(draft),
        mapper: (value) => value as OnboardingResult,
      );

      final NetworkException? profileError =
          profileEither.fold((error) => error, (_) => null);

      // "Profil sudah lengkap" is a refusal that means step one is already done
      // — the account completed it in an earlier session, or a retry lost the
      // in-memory flag. Treating it as a failure would strand the user on a
      // form they can never submit, so it counts as the success it describes.
      if (profileError != null && !_isProfileAlreadyComplete(profileError)) {
        emit(const OnboardingInitial());
        return (result: null, error: profileError);
      }

      _profileSubmitted = true;
    }

    final either = await apiCall<OnboardingResult>(
      func: _dataSource.registerBankSampah(request),
      mapper: (value) => value as OnboardingResult,
    );
    emit(const OnboardingInitial());

    return either.fold(
      (error) => (result: null, error: error),
      (result) {
        // Both steps are in. Nothing left to resubmit or prefill.
        clearProfileDraft();
        return (result: result, error: null);
      },
    );
  }

  /// Whether [error] is the backend declining to complete an already-complete
  /// profile.
  ///
  /// Matched on wording because that is all there is: services.py raises a bare
  /// `ValueError("Profil sudah lengkap")` and the view returns it as
  /// `{"error": …}` with no code to key on. The same constraint drives
  /// `classifyInviteAcceptance`.
  bool _isProfileAlreadyComplete(NetworkException error) {
    final message = error.displayMessage.toLowerCase();
    return message.contains('profil') && message.contains('sudah lengkap');
  }
}
