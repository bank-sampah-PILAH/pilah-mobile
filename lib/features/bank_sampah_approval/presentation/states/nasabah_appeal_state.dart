import 'package:equatable/equatable.dart';

/// State of one appeal submission on the membership detail page (PIL-232).
///
/// Scoped to a single detail-page visit, not persisted list data — the list
/// page reloads the membership itself once an appeal succeeds.
abstract class NasabahAppealState extends Equatable {
  const NasabahAppealState();

  @override
  List<Object?> get props => [];
}

class NasabahAppealIdle extends NasabahAppealState {
  const NasabahAppealIdle();
}

class NasabahAppealSubmitting extends NasabahAppealState {
  const NasabahAppealSubmitting();
}

class NasabahAppealSuccess extends NasabahAppealState {
  const NasabahAppealSuccess();
}

class NasabahAppealFailure extends NasabahAppealState {
  final String message;

  const NasabahAppealFailure(this.message);

  @override
  List<Object?> get props => [message];
}
