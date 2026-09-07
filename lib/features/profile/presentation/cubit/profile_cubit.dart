import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/core/client/api_call.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:pilah_mobile/features/profile/domain/entities/profile_entities.dart';
import 'package:pilah_mobile/features/profile/presentation/cubit/profile_state.dart';

/// App-scoped rather than page-scoped: the WhatsApp template it loads is also
/// read by the transaksi success flow, which builds the wa.me notification from
/// it. A per-page factory would leave that flow with nothing to read.
@lazySingleton
class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRemoteDataSource _dataSource;
  final ImagePicker _picker;
  final ImageCropper _cropper;

  ProfileCubit(this._dataSource, this._picker, this._cropper)
      : super(const ProfileState());

  /// Loads the bank sampah profile, WhatsApp template and team roster. The bank
  /// profile is essential (a failure shows the error screen); the template and
  /// team degrade gracefully so a partial outage still renders the page.
  ///
  /// Pass [silent] to skip the loading emit — pull-to-refresh already shows a
  /// spinner, and the loading state swaps the whole tab body for a centred
  /// spinner, which would tear the RefreshIndicator out of the tree mid-pull.
  /// [silent] only applies when there is a loaded profile to keep: otherwise
  /// the page has nothing to render, so a real loading state is emitted.
  Future<void> load({bool silent = false}) async {
    if (!silent || state.status != ProfileStatus.loaded) {
      emit(const ProfileState(status: ProfileStatus.loading));
    }

    final bankEither = await apiCall<BankSampahProfile>(
      func: _dataSource.getBankSampah(),
      mapper: (value) => value as BankSampahProfile,
    );

    await bankEither.fold(
      (error) async => emit(ProfileState(
          status: ProfileStatus.error, error: error.displayMessage)),
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
        waTemplate: (state.waTemplate ?? const WaTemplate(template: ''))
            .copyWith(template: template),
      ));
      return null;
    } on Exception catch (e) {
      emit(state.copyWith(isSavingTemplate: false));
      return NetworkException.handleException(e);
    }
  }

  /// Opens the gallery, then a square cropper, holding the result in state for
  /// the next save. Nothing is uploaded here — a pick the user then abandons
  /// should leave the stored logo untouched.
  ///
  /// Cropping is not optional polish. The logo is only ever drawn inside a
  /// circle, so an uncropped landscape photo arrives already ruined: the avatar
  /// takes the centre and throws the sides away, and the user finds out after
  /// saving. Locking the frame to 1:1 makes what they choose what they get.
  ///
  /// Backing out at either step returns null and is not an error. The state is
  /// left exactly as it was, including any logo picked earlier — abandoning a
  /// crop is not a request to undo the previous choice.
  ///
  /// Sizing and compression belong to the cropper, not the picker: the picker
  /// runs first, and anything it shrinks is detail the crop no longer has to
  /// work with. Doing it once, at the end, also avoids encoding the same JPEG
  /// twice. The 1024px/quality-70 result lands far under the API's 5 MB cap,
  /// which a modern phone camera would otherwise breach on its own.
  Future<void> pickLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final CroppedFile? cropped = await _cropper.cropImage(
      sourcePath: image.path,
      maxWidth: 1024,
      maxHeight: 1024,
      compressQuality: 70,
      // Also normalises whatever the gallery handed over — an iOS HEIC or a
      // WebP would otherwise reach an API that only accepts JPG and PNG.
      compressFormat: ImageCompressFormat.jpg,
      // Setting this locks the cropper to 1:1 outright; the per-platform flags
      // below keep the UI from offering a freedom the ratio does not allow.
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Potong Logo',
          toolbarColor: AppColors.greenDark,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: AppColors.greenDark,
          // The crop overlay is drawn as a circle, matching the avatar the
          // result goes into. The written file is still square — the circle is
          // a guide, so the user frames against the shape they will actually
          // see instead of guessing at the corners.
          cropStyle: CropStyle.circle,
          lockAspectRatio: true,
          initAspectRatio: CropAspectRatioPreset.square,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
        ),
        IOSUiSettings(
          title: 'Potong Logo',
          cropStyle: CropStyle.circle,
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
        ),
      ],
    );
    if (cropped == null) return;

    emit(state.copyWith(selectedLogoFile: File(cropped.path)));
  }

  /// Persists the editable bank sampah fields via `PUT /bank-sampah/me`.
  /// Returns `null` on success, otherwise the [NetworkException] so the page can
  /// surface backend validation (e.g. an invalid phone number, or a logo the
  /// API refuses for its format or size).
  ///
  /// Carries the pending logo when there is one. It is only released once the
  /// response is in hand — a failed save keeps the pick, so the user can retry
  /// without hunting through the gallery again.
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
        fotoLogoPath: state.selectedLogoFile?.path,
      );
      emit(state.copyWith(bankSampah: updated, clearSelectedLogo: true));
      return null;
    } on Exception catch (e) {
      return NetworkException.handleException(e);
    }
  }

  /// Clears cached data and returns to the initial state (used on logout, since
  /// this cubit is an app-scoped singleton that outlives a session).
  ///
  /// [ProfileState.selectedLogoFile] is the reason this matters beyond stale
  /// data: it is a path into the previous user's gallery, and left behind it
  /// would be uploaded as the next bank sampah's logo on their first save.
  void reset() => emit(const ProfileState());

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
