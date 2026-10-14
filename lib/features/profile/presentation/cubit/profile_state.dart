import 'dart:io';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:pilah_mobile/features/profile/domain/entities/profile_entities.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final BankSampahProfile? bankSampah;
  final WaTemplate? waTemplate;
  final List<TeamMember> team;
  final String? error;
  final bool isSavingTemplate;

  /// A logo the user has picked but not yet saved on native platforms.
  final File? selectedLogoFile;

  /// Browser-selected image bytes and filename, held until the profile saves.
  final Uint8List? selectedLogoBytes;
  final String? selectedLogoFilename;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.bankSampah,
    this.waTemplate,
    this.team = const [],
    this.error,
    this.isSavingTemplate = false,
    this.selectedLogoFile,
    this.selectedLogoBytes,
    this.selectedLogoFilename,
  });

  /// [clearSelectedLogo] drops the pending pick, which `selectedLogoFile: null`
  /// cannot express — every field here falls back to the current value, so
  /// passing null is indistinguishable from not passing it. A save that
  /// succeeded needs to let go of the file: the uploaded logo is on the entity
  /// by then, and keeping the local one would leave the avatar showing a
  /// preview of something already stored.
  ProfileState copyWith({
    ProfileStatus? status,
    BankSampahProfile? bankSampah,
    WaTemplate? waTemplate,
    List<TeamMember>? team,
    String? error,
    bool? isSavingTemplate,
    File? selectedLogoFile,
    Uint8List? selectedLogoBytes,
    String? selectedLogoFilename,
    bool clearSelectedLogo = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      bankSampah: bankSampah ?? this.bankSampah,
      waTemplate: waTemplate ?? this.waTemplate,
      team: team ?? this.team,
      error: error ?? this.error,
      isSavingTemplate: isSavingTemplate ?? this.isSavingTemplate,
      selectedLogoFile: clearSelectedLogo
          ? null
          : (selectedLogoFile ?? this.selectedLogoFile),
      selectedLogoBytes: clearSelectedLogo
          ? null
          : (selectedLogoBytes ?? this.selectedLogoBytes),
      selectedLogoFilename: clearSelectedLogo
          ? null
          : (selectedLogoFilename ?? this.selectedLogoFilename),
    );
  }

  @override
  List<Object?> get props => [
        status,
        bankSampah,
        waTemplate,
        team,
        error,
        isSavingTemplate,
        // Path, not the File: two File objects for the same path are not equal,
        // so re-picking the same image would look like a change and rebuild for
        // nothing.
        selectedLogoFile?.path,
        selectedLogoBytes,
        selectedLogoFilename,
      ];
}
