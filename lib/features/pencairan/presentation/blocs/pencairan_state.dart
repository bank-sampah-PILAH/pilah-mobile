import 'package:equatable/equatable.dart';

abstract class PencairanState extends Equatable {
  const PencairanState();
  @override
  List<Object?> get props => [];
}

class PencairanInitialState extends PencairanState {
  const PencairanInitialState();
}

class PencairanLoadingState extends PencairanState {
  const PencairanLoadingState();
}

class PencairanSuccessState extends PencairanState {
  final dynamic data;
  const PencairanSuccessState({required this.data});
  @override
  List<Object?> get props => [data];
}

class PencairanErrorState extends PencairanState {
  final String message;
  const PencairanErrorState({required this.message});
  @override
  List<Object?> get props => [message];
}
