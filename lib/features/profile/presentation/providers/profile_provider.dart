import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/core/client/api_call.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/location_service.dart';
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
      state = const ProfileState(status: ProfileStatus.loading);
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
        if (!ref.mounted) return;
        state = ProfileState(
          status: ProfileStatus.loaded,
          bankSampah: bank,
          waTemplate: waEither.fold((_) => null, (value) => value),
          team: teamEither.fold((_) => const <TeamMember>[], (value) => value),
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
  /// without hunting through the gallery again. [lokasi] goes out whenever the
  /// caller passes one; omitting it leaves the stored coordinates untouched.
  Future<NetworkException?> updateBankSampah({
    required String nama,
    required String alamat,
    required String noHpPic,
    Lokasi? lokasi,
  }) async {
    try {
      final updated = await _dataSource.updateBankSampah(
        nama: nama,
        alamat: alamat,
        kota: state.bankSampah?.kota,
        noHpPic: noHpPic,
        fotoLogoBytes: state.selectedLogoBytes,
        fotoLogoFilename: state.selectedLogoFilename,
        lokasi: lokasi,
      );
      if (!ref.mounted) return null;
      state = state.copyWith(bankSampah: updated, clearSelectedLogo: true);
      return null;
    } on Exception catch (e) {
      return NetworkException.handleException(e);
    }
  }

  /// The bank profile for background callers (the dashboard's coordinate
  /// prompt), without the template/team fetches a full [load] performs.
  ///
  /// Returns the cached profile when there is one; otherwise a single
  /// `bank-sampah/me` call, folded into the current state rather than a fresh
  /// emit, so it cannot clobber a concurrent save or the WA template already
  /// held here. Null means the fetch failed or the session has no bank —
  /// a background prompt must never surface an error for that.
  Future<BankSampahProfile?> ensureBank() async {
    final cached = state.bankSampah;
    if (cached != null) return cached;
    final either = await apiCall<BankSampahProfile>(
      func: _dataSource.getBankSampah(),
      mapper: (value) => value as BankSampahProfile,
    );
    return either.fold(
      (_) => null,
      (bank) {
        // Cached for the next caller (ProfilePage itself uses [load] and a
        // fresh GET, so a stale window is possible but harmless for display).
        emit(state.copyWith(bankSampah: bank));
        return bank;
      },
    );
  }

  /// Clears cached data and returns to the initial state (used on logout, since
  /// this notifier is an app-scoped singleton that outlives a session).
  ///
  /// Pending logo bytes must not be uploaded by the next signed-in user.
  void reset() => state = const ProfileState();

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
