import 'package:pilah_mobile/features/authentication/presentation/blocs/states/post_login_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/use_cases/authentication_use_cases.dart';
import '../../domain/use_cases/login_with_google_usecase.dart';
import 'authentication_events.dart';
import 'authentication_states.dart';
import 'events/check_session_events.dart';
import 'events/login_refresh_events.dart';
import 'events/login_with_google_events.dart';
import 'events/logout_events.dart';
import 'events/post_login_events.dart';
import 'events/refresh_user_events.dart';

@Injectable()
class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationStates> {
  final AuthenticationUseCases _useCases;
  // ignore: unused_field - Will be re-enabled when backend API is ready
  final LoginWithGoogleUseCase _loginWithGoogleUseCase;

  AuthenticationBloc(this._useCases, this._loginWithGoogleUseCase)
      : super(AuthenticationInitial()) {
    on<PostLoginEvent>(_onPostLoginEvent);
    on<LoginRefreshEvent>(_onLoginRefreshEvent);
    on<LoginWithGoogleRequested>(_onLoginWithGoogleRequested);
    on<CheckSessionRequested>(_onCheckSessionRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<RefreshUserRequested>(_onRefreshUserRequested);
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

    final response = await _loginWithGoogleUseCase.execute(event.idToken);

    response.fold(
      (failure) {
        emitter(AuthenticationFailure(
            message: failure.message ?? 'Unknown error occurred'));
      },
      (entity) {
        if (entity != null) {
          emitter(Authenticated(authEntity: entity));
        } else {
          emitter(
              AuthenticationFailure(message: 'Invalid response from server'));
        }
      },
    );
  }

  /// Restores a persisted session on app start. Emits [Authenticated] when the
  /// token is still valid (per `GET /auth/me`), otherwise clears the stale
  /// token and emits [Unauthenticated] so the splash routes to login.
  Future _onCheckSessionRequested(
    CheckSessionRequested event,
    Emitter<AuthenticationStates> emitter,
  ) async {
    emitter(AuthenticationLoading());

    if (!await _useCases.hasSession()) {
      emitter(Unauthenticated());
      return;
    }

    final result = await _useCases.getMe();
    await result.fold(
      (failure) async {
        // Token missing/expired/invalid — drop the stale session.
        await _useCases.logout();
        emitter(Unauthenticated());
      },
      (entity) async {
        emitter(Authenticated(authEntity: entity));
      },
    );
  }

  Future _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthenticationStates> emitter,
  ) async {
    emitter(AuthenticationLoading());
    await _useCases.logout();
    emitter(Unauthenticated());
  }

  /// Silently re-fetches the current user (no loading state, keeps the current
  /// session on failure) so the UI reflects freshly-saved profile data.
  Future _onRefreshUserRequested(
    RefreshUserRequested event,
    Emitter<AuthenticationStates> emitter,
  ) async {
    final result = await _useCases.getMe();
    result.fold(
      (_) {},
      (entity) => emitter(Authenticated(authEntity: entity)),
    );
  }
}
