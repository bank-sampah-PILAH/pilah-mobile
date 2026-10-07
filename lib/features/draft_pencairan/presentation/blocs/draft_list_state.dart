import 'package:equatable/equatable.dart';

import '../../domain/model/draft_pencairan.dart';

enum DraftListStatus { loading, loaded, failure }

class DraftListState extends Equatable {
  final DraftListStatus status;
  final List<DraftRingkasan> drafts;

  /// Null shows every status.
  final DraftStatus? filter;
  final String? errorMessage;

  const DraftListState({
    this.status = DraftListStatus.loading,
    this.drafts = const [],
    this.filter,
    this.errorMessage,
  });

  List<DraftRingkasan> get tampil => filter == null
      ? drafts
      : drafts.where((draft) => draft.status == filter).toList();

  DraftListState copyWith({
    DraftListStatus? status,
    List<DraftRingkasan>? drafts,
    DraftStatus? Function()? filter,
    String? Function()? errorMessage,
  }) =>
      DraftListState(
        status: status ?? this.status,
        drafts: drafts ?? this.drafts,
        filter: filter != null ? filter() : this.filter,
        errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      );

  @override
  List<Object?> get props => [status, drafts, filter, errorMessage];
}
