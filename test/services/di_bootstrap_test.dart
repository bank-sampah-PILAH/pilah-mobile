import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/constants/app_key.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/services/di.dart';

void main() {
  tearDown(() => di.reset());

  for (final environment in [AppKey.devEnv, AppKey.prodEnv]) {
    test('bootstraps authentication from the real $environment graph',
        () async {
      dotenv.loadFromString(envString: '''
BASE_URL_DEV=https://pilah-be-staging.fly.dev
BASE_URL_PROD=https://backend.run.app
ENABLE_DEMO_LOGIN=false
''');
      // The same public bootstrap and resolution used by main_* and App.
      configureDependencies(environment: environment);
      expect(di.isRegistered<bool>(), isFalse);
      final bloc = di<AuthenticationBloc>();
      expect(bloc.state, isA<AuthenticationInitial>());
      await bloc.close();
    });
  }
}
