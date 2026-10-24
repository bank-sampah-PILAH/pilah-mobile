import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/domain/use_cases/authentication_use_cases.dart';
import 'package:pilah_mobile/features/authentication/domain/use_cases/login_with_google_usecase.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/services/di.dart';

final authenticationProvider =
    NotifierProvider<AuthenticationNotifier, AuthenticationStates>(
  () => AuthenticationNotifier(
    di<AuthenticationUseCases>(),
    di<LoginWithGoogleUseCase>(),
  ),
);

class AuthenticationNotifier extends Notifier<AuthenticationStates> {
  AuthenticationNotifier(
    this._useCases,
    this._loginWithGoogleUseCase, {
    bool? isWebOverride,
  })  : _isWeb = isWebOverride ?? kIsWeb,
        super();

  final AuthenticationUseCases _useCases;
  final LoginWithGoogleUseCase _loginWithGoogleUseCase;
  final bool _isWeb;
  AuthEntity? _activeSession;

  @override
  AuthenticationStates build() => AuthenticationInitial();

  Future<void> postLogin(String email, String password) async {
    _rememberCurrentSession();
    state = AuthenticationLoading();
    final response = await _useCases.postLogin(email, password);
    if (!ref.mounted) return;
    response.fold(
      (failure) => state = AuthenticationFailure(
        message: failure.displayMessage,
      ),
      _emitAuthenticated,
    );
  }

  void refreshLogin() {
    if (state is AuthenticationFailure) {
      state = AuthenticationInitial();
    }
  }

  Future<void> loginWithGoogle(String idToken) async {
    _rememberCurrentSession();
    state = AuthenticationLoading();
    final response = await _loginWithGoogleUseCase.execute(idToken);
    if (!ref.mounted) return;
    response.fold(
      (failure) => state = AuthenticationFailure(
        message: failure.message ?? 'Unknown error occurred',
      ),
      (outcome) {
        if (outcome is GoogleSession) {
          _emitAuthenticated(outcome.auth);
        } else if (outcome is GoogleRegistrationRequired) {
          state = GoogleRegistrationPending(registration: outcome);
        } else {
          state = AuthenticationFailure(
            message: 'Invalid response from server',
          );
        }
      },
    );
  }

  Future<void> registerGoogleRole(GoogleRegistrationRole role) async {
    final registration = switch (state) {
      GoogleRegistrationPending(:final registration) => registration,
      GoogleRegistrationFailure(:final registration) => registration,
      _ => null,
    };
    if (registration == null) return;

    state = GoogleRegistrationSubmitting(
      registration: registration,
      role: role,
    );
    final result = await _loginWithGoogleUseCase.register(
      registrationToken: registration.registrationToken,
      role: role,
    );
    if (!ref.mounted) return;
    result.fold(
      (failure) {
        final data = failure.response?.data;
        final code = data is Map ? data['code']?.toString() : null;
        if (code == 'registration_token_expired' ||
            code == 'registration_token_invalid') {
          state = GoogleRegistrationExpired(message: failure.displayMessage);
        } else {
          state = GoogleRegistrationFailure(
            registration: registration,
            message: failure.displayMessage,
          );
        }
      },
      _emitAuthenticated,
    );
  }

  /// Disconnect Google too; otherwise the next authenticate call reuses its
  /// account and cannot switch identities. PILAH state is still cleared on error.
  Future<void> changeGoogleAccount() async {
    _rememberCurrentSession();
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {}
    if (ref.mounted) state = AuthenticationInitial();
  }

  /// Restores a persisted session on app start; rejected tokens are cleared.
  Future<void> checkSession() async {
    _rememberCurrentSession();
    state = AuthenticationLoading();
    if (!await _useCases.hasSession()) {
      if (ref.mounted) _emitUnauthenticated();
      return;
    }

    final result = await _useCases.getMe();
    if (!ref.mounted) return;
    await result.fold(
      (failure) async {
        await _useCases.logout();
        if (ref.mounted) _emitUnauthenticated();
      },
      (entity) async => _emitAuthenticated(entity),
    );
  }

  Future<void> logout() async {
    state = AuthenticationLoading();
    if (_isWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Clear the PILAH session even if Google's sign-out fails.
      }
    }
    await _useCases.logout();
    if (ref.mounted) _emitUnauthenticated();
  }

  /// Refreshes user data without a loading state and keeps the session on error.
  Future<void> refreshUser() async {
    final result = await _useCases.getMe();
    if (!ref.mounted) return;
    result.fold((_) {}, _emitAuthenticated);
  }

  void _rememberCurrentSession() {
    final current = state;
    if (current is Authenticated) _activeSession = current.authEntity;
  }

  void _emitAuthenticated(AuthEntity entity) {
    if (!ref.mounted) return;
    final current = state;
    final previous = _activeSession ??
        (current is Authenticated ? current.authEntity : null);
    final previousId = previous?.id;
    final nextId = entity.id;
    final sameAccount = previousId != null && nextId != null
        ? previousId == nextId
        : previous?.email.trim().toLowerCase() ==
            entity.email.trim().toLowerCase();
    if (previous != null && !sameAccount) _emitUnauthenticated();
    _activeSession = entity;
    state = Authenticated(authEntity: entity);
  }

  void _emitUnauthenticated() {
    _activeSession = null;
    state = Unauthenticated();
  }
}
