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

  Future<void> getSomething() async {
    emit(const PencairanLoadingState());
    final result = await _useCases.getSomething();
    result.fold(
      (failure) => emit(PencairanErrorState(message: failure.message ?? '')),
      (data)    => emit(PencairanSuccessState(data: data)),
    );
  }
}
