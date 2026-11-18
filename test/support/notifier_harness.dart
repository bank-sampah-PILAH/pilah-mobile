import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotifierHarness<T extends Notifier<S>, S> {
  NotifierHarness(this.provider, this.create) {
    container = ProviderContainer(
      overrides: [provider.overrideWith(create)],
    );
    subscription = container.listen(provider, (_, state) => states.add(state));
    notifier = container.read(provider.notifier);
  }

  final NotifierProvider<T, S> provider;
  final T Function() create;
  final states = <S>[];
  late final ProviderContainer container;
  late final ProviderSubscription<S> subscription;
  late final T notifier;
  bool _disposed = false;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    subscription.close();
    container.dispose();
  }
}
