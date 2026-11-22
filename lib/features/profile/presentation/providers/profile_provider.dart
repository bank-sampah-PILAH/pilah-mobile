import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/core/client/api_call.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:pilah_mobile/features/profile/domain/entities/profile_entities.dart';
import 'package:pilah_mobile/features/profile/presentation/states/profile_state.dart';
import 'package:pilah_mobile/services/di.dart';

/// App-scoped because the transaksi success flow also reads the WA template.
final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(
  () => ProfileNotifier(
    di<ProfileRemoteDataSource>(),
    di<ImagePicker>(),
    di<ImageCropper>(),
  ),
);

class ProfileNotifier extends Notifier<ProfileState> {
  final ProfileRemoteDataSource _dataSource;
  final ImagePicker _picker;
  final ImageCropper _cropper;

  ProfileNotifier(this._dataSource, this._picker, this._cropper, {bool? isWeb})
      : _isWeb = isWeb ?? kIsWeb;

  final bool _isWeb;

  @override
  ProfileState build() => const ProfileState();

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
      state = const ProfileState(
        status: ProfileStatus.loading,
        isLoadingInvite: true,
      );
    }

    final bankEither = await apiCall<BankSampahProfile>(
      func: _dataSource.getBankSampah(),
      mapper: (value) => value as BankSampahProfile,
    );

    if (!ref.mounted) return;
    await bankEither.fold(
      (error) async => state = ProfileState(
          status: ProfileStatus.error, error: error.displayMessage),
      (bank) async {
        final waEither = await apiCall<WaTemplate>(
          func: _dataSource.getWaTemplate(),
          mapper: (value) => value as WaTemplate,
        );
        final teamEither = await apiCall<List<TeamMember>>(
          func: _dataSource.getTeam(),
          mapper: (value) => value as List<TeamMember>,
        );
        final team =
            teamEither.fold((_) => const <TeamMember>[], (value) => value);
        TeamInvite? invite;
        String? inviteError;
        if (team.any((member) => member.isCurrentUser && member.isPrimary)) {
          final inviteEither = await apiCall<TeamInvite?>(
            func: _dataSource.getTeamInvite(),
            mapper: (value) => value as TeamInvite?,
          );
          invite = inviteEither.fold((_) => null, (value) => value);
          inviteError =
              inviteEither.fold((error) => error.displayMessage, (_) => null);
        }
        if (!ref.mounted) return;
        state = ProfileState(
          status: ProfileStatus.loaded,
          bankSampah: bank,
          waTemplate: waEither.fold((_) => null, (value) => value),
          team: team,
          invite: invite,
          inviteError: inviteError,
        );
      },
    );
  }

  /// Persists the WhatsApp template. Returns `null` on success, otherwise the
  /// [NetworkException] so the page can show the error.
  Future<NetworkException?> saveWaTemplate(String template) async {
    state = state.copyWith(isSavingTemplate: true);
    try {
      await _dataSource.updateWaTemplate(template);
      if (!ref.mounted) return null;
      state = state.copyWith(
        isSavingTemplate: false,
        waTemplate: (state.waTemplate ?? const WaTemplate(template: ''))
            .copyWith(template: template),
      );
      return null;
    } on Exception catch (e) {
      if (!ref.mounted) return NetworkException.handleException(e);
      state = state.copyWith(isSavingTemplate: false);
      return NetworkException.handleException(e);
    }
  }

  /// Opens the gallery and holds the pending logo for the next save. Nothing
  /// is uploaded here — a pick the user then abandons leaves the stored logo
  /// untouched.
  ///
  /// Mobile uses a square cropper and compresses the result to a 1024px JPEG.
  /// Web keeps the browser-selected bytes without opening the native cropper.
  /// The preview uses the same centered circular crop as the saved logo.
  ///
  /// Backing out of the native picker or cropper returns null and is not an
  /// error. The state stays as it was, including any logo picked earlier.
  Future<void> pickLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null || !ref.mounted) return;

    if (_isWeb) {
      final bytes = await image.readAsBytes();
      if (!ref.mounted) return;
      state = state.copyWith(
        selectedLogoBytes: bytes,
        selectedLogoFilename: image.name,
      );
      return;
    }

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
    if (cropped == null || !ref.mounted) return;
    final bytes = await cropped.readAsBytes();
    if (!ref.mounted) return;

    state = state.copyWith(
      selectedLogoBytes: bytes,
      selectedLogoFilename: XFile(cropped.path).name,
    );
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
        fotoLogoBytes: state.selectedLogoBytes,
        fotoLogoFilename: state.selectedLogoFilename,
      );
      if (!ref.mounted) return null;
      state = state.copyWith(bankSampah: updated, clearSelectedLogo: true);
      return null;
    } on Exception catch (e) {
      return NetworkException.handleException(e);
    }
  }

  /// Clears cached data and returns to the initial state (used on logout, since
  /// this notifier is an app-scoped singleton that outlives a session).
  ///
  /// Pending logo bytes must not be uploaded by the next signed-in user.
  void reset() => state = const ProfileState();

  /// Hands the Pengurus Utama role to the pengurus [id]. The roster in the
  /// answer replaces the one on screen, so who may invite and who may be acted
  /// on follows at once; the invitation link goes with it, as only the Pengurus
  /// Utama may see or create one. Returns `null` on success, otherwise the
  /// [NetworkException].
  Future<NetworkException?> transferPrimary(String id) async {
    state = state.copyWith(isChangingTeam: true);
    final either = await apiCall<List<TeamMember>>(
      func: _dataSource.transferPrimary(id),
      mapper: (value) => value as List<TeamMember>,
    );
    if (!ref.mounted) return null;
    return either.fold(
      (error) {
        state = state.copyWith(isChangingTeam: false);
        return error;
      },
      (team) {
        state = state.copyWith(
          isChangingTeam: false,
          team: team,
          clearInvite: true,
          clearInviteError: true,
        );
        return null;
      },
    );
  }

  /// Removes the pengurus [id] from the bank sampah. The answer carries no
  /// roster, so the row simply leaves the one on screen. Returns `null` on
  /// success, otherwise the [NetworkException].
  Future<NetworkException?> removeMember(String id) async {
    state = state.copyWith(isChangingTeam: true);
    final either = await apiCall<void>(
      func: _dataSource.removeMember(id),
      mapper: (_) {},
    );
    if (!ref.mounted) return null;
    return either.fold(
      (error) {
        state = state.copyWith(isChangingTeam: false);
        return error;
      },
      (_) {
        state = state.copyWith(
          isChangingTeam: false,
          team: [
            for (final member in state.team)
              if (member.id != id) member,
          ],
        );
        return null;
      },
    );
  }

  /// Reads the roster again after the server refused to create an invitation.
  /// A user who is still the Pengurus Utama was refused for another reason
  /// (the bank sampah is not active, say), so the message stays on the screen.
  Future<void> _reloadAfterRefusal(String message) async {
    await load(silent: true);
    if (!ref.mounted) return;
    if (state.team.any((member) => member.isCurrentUser && member.isPrimary)) {
      state = state.copyWith(inviteError: message);
    }
  }

  /// Explicitly creates or replaces the team's invitation link.
  Future<NetworkException?> createInvite() async {
    state = state.copyWith(isCreatingInvite: true, clearInviteError: true);
    final either = await apiCall<TeamInvite>(
      func: _dataSource.createTeamInvite(),
      mapper: (value) => value as TeamInvite,
    );
    if (!ref.mounted) return null;
    return either.fold(
      (error) {
        state = state.copyWith(
          isCreatingInvite: false,
          inviteError: error.displayMessage,
        );
        // Only the Pengurus Utama may create a link, so a refusal means this
        // screen is out of date: the role has moved on. Reading the roster
        // again makes the screen show what the server already knows, without
        // holding back the message.
        if (error.response?.statusCode == 403) {
          unawaited(_reloadAfterRefusal(error.displayMessage));
        }
        return error;
      },
      (invite) {
        state = state.copyWith(
          isCreatingInvite: false,
          invite: invite,
          clearInviteError: true,
        );
        return null;
      },
    );
  }
}
