import 'package:equatable/equatable.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';

sealed class JadwalState extends Equatable {
  const JadwalState();

  @override
  List<Object?> get props => [];
}

class JadwalInitial extends JadwalState {
  const JadwalInitial();
}

class JadwalLoading extends JadwalState {
  const JadwalLoading();
}

class JadwalLoaded extends JadwalState {
  final List<JadwalEntity> items;
  final bool isSaving;

  const JadwalLoaded(this.items, {this.isSaving = false});

  @override
  List<Object?> get props => [items, isSaving];
}

class JadwalError extends JadwalState {
  final String message;

  const JadwalError(this.message);

  @override
  List<Object?> get props => [message];
}
