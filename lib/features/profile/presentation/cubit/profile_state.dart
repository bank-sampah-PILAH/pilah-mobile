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

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.bankSampah,
    this.waTemplate,
    this.team = const [],
    this.error,
    this.isSavingTemplate = false,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    BankSampahProfile? bankSampah,
    WaTemplate? waTemplate,
    List<TeamMember>? team,
    String? error,
    bool? isSavingTemplate,
  }) {
    return ProfileState(
      status: status ?? this.status,
      bankSampah: bankSampah ?? this.bankSampah,
      waTemplate: waTemplate ?? this.waTemplate,
      team: team ?? this.team,
      error: error ?? this.error,
      isSavingTemplate: isSavingTemplate ?? this.isSavingTemplate,
    );
  }

  @override
  List<Object?> get props =>
      [status, bankSampah, waTemplate, team, error, isSavingTemplate];
}
