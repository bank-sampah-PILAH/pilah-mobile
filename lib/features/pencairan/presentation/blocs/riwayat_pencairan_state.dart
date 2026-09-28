import 'package:equatable/equatable.dart';

import '../../domain/model/pencairan.dart';
import '../../domain/model/riwayat_pencairan_filter.dart';

enum RiwayatStatus { initial, loading, loaded, failure }

class RiwayatPencairanState extends Equatable {
  final RiwayatStatus status;
  final RiwayatPencairanFilter filter;
  final List<Pencairan> items;
  final String? errorMessage;

  const RiwayatPencairanState({
    this.status = RiwayatStatus.initial,
    this.filter = const RiwayatPencairanFilter(),
    this.items = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, filter, items, errorMessage];
}
