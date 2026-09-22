import 'package:injectable/injectable.dart';

abstract class PencairanLocalDataSources {}

@LazySingleton(as: PencairanLocalDataSources)
class PencairanLocalDataSourcesImpl implements PencairanLocalDataSources {
  const PencairanLocalDataSourcesImpl();
}
