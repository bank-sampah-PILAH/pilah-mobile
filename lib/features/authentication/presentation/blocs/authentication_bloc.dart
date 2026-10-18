import 'package:pilah_mobile/features/authentication/presentation/blocs/states/post_login_states.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

import '../../domain/use_cases/authentication_use_cases.dart';
import '../../domain/use_cases/login_with_google_usecase.dart';
import '../../domain/model/auth.dart';
import 'authentication_events.dart';
import 'authentication_states.dart';
import 'events/check_session_events.dart';
import 'events/login_refresh_events.dart';
import 'events/login_with_google_events.dart';
import 'events/logout_events.dart';
import 'events/post_login_events.dart';
import 'events/refresh_user_events.dart';
import 'events/register_google_role_events.dart';

@Injectable()
class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationStates> {
  final AuthenticationUseCases _useCases;
  final LoginWithGoogleUseCase _loginWithGoogleUseCase;
  final bool _isWeb;
  AuthEntity? _activeSession;

  AuthenticationBloc(
    this._useCases,
    this._loginWithGoogleUseCase, {
    @ignoreParam bool? isWebOverride,
  })  : _isWeb = isWebOverride ?? kIsWeb,
        super(AuthenticationInitial()) {
    on<PostLoginEvent>(_onPostLoginEvent);
    on<LoginRefreshEvent>(_onLoginRefreshEvent);
    on<LoginWithGoogleRequested>(_onLoginWithGoogleRequested);
    on<RegisterGoogleRoleRequested>(_onRegisterGoogleRoleRequested);
    on<ChangeGoogleAccountRequested>(_onChangeGoogleAccountRequested);
    on<CheckSessionRequested>(_onCheckSessionRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<RefreshUserRequested>(_onRefreshUserRequested);
  }

  Future _onPostLoginEvent(
      PostLoginEvent event, Emitter<AuthenticationStates> emitter) async {
    final current = state;
    if (current is Authenticated) _activeSession = current.authEntity;
    emitter(AuthenticationLoading());
    final response = await _useCases.postLogin(event.email, event.password);
    response.fold(
      (failure) =>
          emitter(AuthenticationFailure(message: failure.displayMessage)),
      (entity) => _emitAuthenticated(emitter, entity),
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
    final current = state;
    if (current is Authenticated) _activeSession = current.authEntity;
    emitter(AuthenticationLoading());

    final response = await _loginWithGoogleUseCase.execute(event.idToken);

    response.fold(
      (failure) {
        emitter(AuthenticationFailure(
            message: failure.message ?? 'Unknown error occurred'));
      },
      (outcome) {
        if (outcome is GoogleSession) {
          _emitAuthenticated(emitter, outcome.auth);
        } else if (outcome is GoogleRegistrationRequired) {
          emitter(GoogleRegistrationPending(registration: outcome));
        } else {
          emitter(
              AuthenticationFailure(message: 'Invalid response from server'));
        }
      },
    );
  }

  Future<void> _onRegisterGoogleRoleRequested(
    RegisterGoogleRoleRequested event,
    Emitter<AuthenticationStates> emitter,
  ) async {
    final current = state;
    final registration = switch (current) {
      GoogleRegistrationPending() => current.registration,
      GoogleRegistrationFailure() => current.registration,
      _ => null,
    };
    if (registration == null) return;

    emitter(GoogleRegistrationSubmitting(
      registration: registration,
      role: event.role,
    ));
    final result = await _loginWithGoogleUseCase.register(
      registrationToken: registration.registrationToken,
      role: event.role,
    );
    result.fold(
      (failure) {
        final data = failure.response?.data;
        final code = data is Map ? data['code']?.toString() : null;
        if (code == 'registration_token_expired' ||
            code == 'registration_token_invalid') {
          emitter(GoogleRegistrationExpired(message: failure.displayMessage));
        } else {
          emitter(GoogleRegistrationFailure(
            registration: registration,
            message: failure.displayMessage,
          ));
        }
      },
      (entity) => _emitAuthenticated(emitter, entity),
    );
  }

  /// Also disconnects Google's own session — otherwise the next
  /// `authenticate()` silently returns the same account and "Ganti akun"
  /// can never actually switch. Best-effort: still clears app state if
  /// disconnect fails.
  Future<void> _onChangeGoogleAccountRequested(
    ChangeGoogleAccountRequested event,
    Emitter<AuthenticationStates> emitter,
  ) async {
    final current = state;
    if (current is Authenticated) _activeSession = current.authEntity;
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {}
    emitter(AuthenticationInitial());
  }

  /// Restores a persisted session on app start. Emits [Authenticated] when the
  /// token is still valid (per `GET /auth/me`), otherwise clears the stale
  /// token and emits [Unauthenticated] so the splash routes to login.
  Future _onCheckSessionRequested(
    CheckSessionRequested event,
    Emitter<AuthenticationStates> emitter,
  ) async {
    final current = state;
    if (current is Authenticated) _activeSession = current.authEntity;
    emitter(AuthenticationLoading());

    if (!await _useCases.hasSession()) {
      _emitUnauthenticated(emitter);
      return;
    }

    final result = await _useCases.getMe();
    await result.fold(
      (failure) async {
        // Token missing/expired/invalid — drop the stale session.
        await _useCases.logout();
        _emitUnauthenticated(emitter);
      },
      (entity) async {
        _emitAuthenticated(emitter, entity);
      },
    );
  }

  Future _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthenticationStates> emitter,
  ) async {
    emitter(AuthenticationLoading());
    if (_isWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Still clear the PILAH session if Google's sign-out fails.
      }
    }
    await _useCases.logout();
    _emitUnauthenticated(emitter);
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
      (entity) => _emitAuthenticated(emitter, entity),
    );
  }

  void _emitAuthenticated(
    Emitter<AuthenticationStates> emitter,
    AuthEntity entity,
  ) {
    final current = state;
    final previous = _activeSession ??
        (current is Authenticated ? current.authEntity : null);
    final previousId = previous?.id;
    final nextId = entity.id;
    final sameAccount = previousId != null && nextId != null
        ? previousId == nextId
        : previous?.email.trim().toLowerCase() ==
            entity.email.trim().toLowerCase();
    if (previous != null && !sameAccount) _emitUnauthenticated(emitter);
    _activeSession = entity;
    emitter(Authenticated(authEntity: entity));
  }

  void _emitUnauthenticated(Emitter<AuthenticationStates> emitter) {
    _activeSession = null;
    emitter(Unauthenticated());
  }
}
