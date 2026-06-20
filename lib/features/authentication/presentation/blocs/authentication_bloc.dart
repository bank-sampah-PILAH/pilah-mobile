import 'package:pilah_mobile/features/authentication/presentation/blocs/states/post_login_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/use_cases/authentication_use_cases.dart';
import '../../domain/use_cases/login_with_google_usecase.dart';
import 'authentication_events.dart';
import 'authentication_states.dart';
import 'events/login_refresh_events.dart';
import 'events/login_with_google_events.dart';
import 'events/post_login_events.dart';

@Injectable()
class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationStates> {
  final AuthenticationUseCases _useCases;
  final LoginWithGoogleUseCase _loginWithGoogleUseCase;

  AuthenticationBloc(this._useCases, this._loginWithGoogleUseCase)
      : super(AuthenticationInitial()) {
    on<PostLoginEvent>(_onPostLoginEvent);
    on<LoginRefreshEvent>(_onLoginRefreshEvent);
    on<LoginWithGoogleRequested>(_onLoginWithGoogleRequested);
  }

  Future _onPostLoginEvent(
      PostLoginEvent event, Emitter<AuthenticationStates> emitter) async {
    emitter(PostLoginLoadingState());
    final response = await _useCases.postLogin(event.username, event.password);
    await response.fold(
      (l) {
        emitter(PostLoginErrorState(message: l.message ?? ''));
      },
      (r) async {
        await _useCases.saveToken(r.token, r.token);
        emitter(PostLoginSuccessState(auth: r));
      },
    );
  }

  Future _onLoginRefreshEvent(
    LoginRefreshEvent event,
    Emitter<AuthenticationStates> emitter,
  ) async {
    if (state is PostLoginErrorState || state is AuthenticationFailure) {
      emitter(AuthenticationInitial());
    }
  }

  Future _onLoginWithGoogleRequested(
    LoginWithGoogleRequested event,
    Emitter<AuthenticationStates> emitter,
  ) async {
    emitter(AuthenticationLoading());

    final result = await _loginWithGoogleUseCase.execute(event.idToken);

    result.fold(
      (failure) {
        emitter(AuthenticationFailure(
          message: failure.message ?? 'Google login failed',
        ));
      },
      (authEntity) {
        if (authEntity != null) {
          emitter(Authenticated(authEntity: authEntity));
        } else {
          emitter(AuthenticationFailure(
            message: 'Google login returned no data',
          ));
        }
      },
    );
  }
}
