import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/di.dart';
import '../../domain/use_cases/{{name.snakeCase()}}_use_cases.dart';
import '{{name.snakeCase()}}_state.dart';

final {{name.snakeCase()}}UseCasesProvider = Provider<{{name.pascalCase()}}UseCases>(
  (ref) => di<{{name.pascalCase()}}UseCases>(),
);

final {{name.snakeCase()}}NotifierProvider =
    AsyncNotifierProvider.autoDispose<{{name.pascalCase()}}Notifier, {{name.pascalCase()}}State>(
  {{name.pascalCase()}}Notifier.new,
);

class {{name.pascalCase()}}Notifier
    extends AutoDisposeAsyncNotifier<{{name.pascalCase()}}State> {
  late {{name.pascalCase()}}UseCases _useCases;

  @override
  Future<{{name.pascalCase()}}State> build() async {
    _useCases = ref.read({{name.snakeCase()}}UseCasesProvider);
    return const {{name.pascalCase()}}InitialState();
  }

  Future<void> getSomething() async {
    state = const AsyncValue.loading();
    final result = await _useCases.getSomething();
    result.fold(
      (failure) => state = AsyncError(
        failure.message ?? 'Error',
        StackTrace.current,
      ),
      (data) => state = AsyncData({{name.pascalCase()}}SuccessState(data: data)),
    );
  }
}
