import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/use_cases/pencairan_use_cases.dart';
import 'pencairan_state.dart';

// Cubit: no event classes needed. Call methods directly from UI.
// Uses flutter_bloc — same package as Bloc, no extra dependency.
@Injectable()
class PencairanCubit extends Cubit<PencairanState> {
  final PencairanUseCases _useCases;

  PencairanCubit(this._useCases) : super(const PencairanInitialState());

  PencairanUseCases get useCases => _useCases;
}
