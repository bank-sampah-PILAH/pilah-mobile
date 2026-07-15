import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/api_call.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:pilah_mobile/features/profile/domain/entities/profile_entities.dart';
import 'package:pilah_mobile/features/profile/presentation/cubit/profile_state.dart';

@injectable
class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRemoteDataSource _dataSource;

  ProfileCubit(this._dataSource) : super(const ProfileState());

  /// Loads the bank sampah profile, WhatsApp template and team roster. The bank
  /// profile is essential (a failure shows the error screen); the template and
  /// team degrade gracefully so a partial outage still renders the page.
  ///
  /// Pass [silent] to skip the loading emit — pull-to-refresh already shows a
  /// spinner, and the loading state swaps the whole tab body for a centred
  /// spinner, which would tear the RefreshIndicator out of the tree mid-pull.
  Future<void> load({bool silent = false}) async {
    if (!silent) emit(const ProfileState(status: ProfileStatus.loading));

    final bankEither = await apiCall<BankSampahProfile>(
      func: _dataSource.getBankSampah(),
      mapper: (value) => value as BankSampahProfile,
    );

    await bankEither.fold(
      (error) async =>
          emit(ProfileState(status: ProfileStatus.error, error: error.displayMessage)),
      (bank) async {
        final waEither = await apiCall<WaTemplate>(
          func: _dataSource.getWaTemplate(),
          mapper: (value) => value as WaTemplate,
        );
        final teamEither = await apiCall<List<TeamMember>>(
          func: _dataSource.getTeam(),
          mapper: (value) => value as List<TeamMember>,
        );
        emit(ProfileState(
          status: ProfileStatus.loaded,
          bankSampah: bank,
          waTemplate: waEither.fold((_) => null, (value) => value),
          team: teamEither.fold((_) => const <TeamMember>[], (value) => value),
        ));
      },
    );
  }

  /// Persists the WhatsApp template. Returns `null` on success, otherwise the
  /// [NetworkException] so the page can show the error.
  Future<NetworkException?> saveWaTemplate(String template) async {
    emit(state.copyWith(isSavingTemplate: true));
    try {
      await _dataSource.updateWaTemplate(template);
      emit(state.copyWith(
        isSavingTemplate: false,
        waTemplate:
            (state.waTemplate ?? const WaTemplate(template: '')).copyWith(template: template),
      ));
      return null;
    } on Exception catch (e) {
      emit(state.copyWith(isSavingTemplate: false));
      return NetworkException.handleException(e);
    }
  }

  /// Persists the editable bank sampah fields via `PUT /bank-sampah/me`.
  /// Returns `null` on success, otherwise the [NetworkException] so the page can
  /// surface backend validation (e.g. an invalid phone number).
  Future<NetworkException?> updateBankSampah({
    required String nama,
    required String alamat,
    required String noHpPic,
  }) async {
    try {
      final updated = await _dataSource.updateBankSampah(
        nama: nama,
        alamat: alamat,
        kota: state.bankSampah?.kota,
        noHpPic: noHpPic,
      );
      emit(state.copyWith(bankSampah: updated));
      return null;
    } on Exception catch (e) {
      return NetworkException.handleException(e);
    }
  }

  /// Generates a team invite link. Returns the URL on success, otherwise the
  /// [NetworkException] (e.g. 403 when the current user is not the primary
  /// pengelola).
  Future<({String? url, NetworkException? error})> generateInvite() async {
    final either = await apiCall<String>(
      func: _dataSource.generateInviteUrl(),
      mapper: (value) => value as String,
    );
    return either.fold(
      (error) => (url: null, error: error),
      (url) => (url: url, error: null),
    );
  }
}
