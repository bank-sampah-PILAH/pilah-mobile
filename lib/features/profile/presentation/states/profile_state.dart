import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:pilah_mobile/features/profile/domain/entities/profile_entities.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final BankSampahProfile? bankSampah;
  final WaTemplate? waTemplate;
  final List<TeamMember> team;
  final TeamInvite? invite;
  final String? inviteError;
  final bool isLoadingInvite;
  final bool isCreatingInvite;
  final String? error;
  final bool isSavingTemplate;

  /// Picker/cropper output, held until the profile saves on any platform.
  final Uint8List? selectedLogoBytes;
  final String? selectedLogoFilename;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.bankSampah,
    this.waTemplate,
    this.team = const [],
    this.invite,
    this.inviteError,
    this.isLoadingInvite = false,
    this.isCreatingInvite = false,
    this.error,
    this.isSavingTemplate = false,
    this.selectedLogoBytes,
    this.selectedLogoFilename,
  });

  /// Clear the pending bytes only after a successful save; failed saves keep
  /// the preview and upload payload available for retry.
  ProfileState copyWith({
    ProfileStatus? status,
    BankSampahProfile? bankSampah,
    WaTemplate? waTemplate,
    List<TeamMember>? team,
    TeamInvite? invite,
    String? inviteError,
    bool clearInviteError = false,
    bool? isLoadingInvite,
    bool? isCreatingInvite,
    String? error,
    bool? isSavingTemplate,
    Uint8List? selectedLogoBytes,
    String? selectedLogoFilename,
    bool clearSelectedLogo = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      bankSampah: bankSampah ?? this.bankSampah,
      waTemplate: waTemplate ?? this.waTemplate,
      team: team ?? this.team,
      invite: invite ?? this.invite,
      inviteError: clearInviteError ? null : (inviteError ?? this.inviteError),
      isLoadingInvite: isLoadingInvite ?? this.isLoadingInvite,
      isCreatingInvite: isCreatingInvite ?? this.isCreatingInvite,
      error: error ?? this.error,
      isSavingTemplate: isSavingTemplate ?? this.isSavingTemplate,
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
        invite,
        inviteError,
        isLoadingInvite,
        isCreatingInvite,
        error,
        isSavingTemplate,
        selectedLogoBytes,
        selectedLogoFilename,
      ];
}
