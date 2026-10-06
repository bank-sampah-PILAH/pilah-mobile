import 'dart:developer';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/login_with_google_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/google_sign_in_error.dart';

import 'google_sign_in_web_button_stub.dart'
    if (dart.library.js_interop) 'google_sign_in_web_button.dart'
    as web_sign_in;

typedef WebGoogleSignInButtonBuilder = Widget Function({
  required bool isLoading,
  required ValueChanged<GoogleSignInAccount> onAuthenticated,
  required ValueChanged<Object> onError,
});

class LoginButton extends StatelessWidget {
  final bool isLoading;

  @visibleForTesting
  final bool? isWebOverride;

  @visibleForTesting
  final WebGoogleSignInButtonBuilder? webButtonBuilderOverride;

  const LoginButton({
    super.key,
    this.isLoading = false,
    @visibleForTesting this.isWebOverride,
    @visibleForTesting this.webButtonBuilderOverride,
  });

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      final googleUser = await GoogleSignIn.instance.authenticate();
      if (!context.mounted) return;
      _submitGoogleUser(context, googleUser);
    } catch (error) {
      _showGoogleSignInError(context, error);
    }
  }

  void _submitGoogleUser(BuildContext context, GoogleSignInAccount googleUser) {
    final idToken = googleUser.authentication.idToken ?? '';
    log('Google Sign-In success: ${googleUser.displayName}');

    if (!context.mounted) return;

    context.read<AuthenticationBloc>().add(
          LoginWithGoogleRequested(
            name: googleUser.displayName ?? 'Unknown',
            email: googleUser.email,
            photoUrl: googleUser.photoUrl ?? '',
            idToken: idToken,
          ),
        );
  }

  void _showGoogleSignInError(BuildContext context, Object error) {
    log('Google Sign-In error: $error');

    // A deliberate cancel/dismiss (message == null) aborts silently — no
    // snackbar. Anything else shows a clean fallback, never the raw exception.
    final message = sanitizeGoogleSignInError(error);
    if (message == null || !context.mounted) return;

    AppNotification.showError(
      context,
      title: 'Login Gagal',
      message: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isWebOverride ?? kIsWeb) {
      final buildWebButton =
          webButtonBuilderOverride ?? web_sign_in.buildWebGoogleSignInButton;
      return buildWebButton(
        isLoading: isLoading,
        onAuthenticated: (user) => _submitGoogleUser(context, user),
        onError: (error) => _showGoogleSignInError(context, error),
      );
    }

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.greenDark,
        ),
      );
    }

    return OutlinedButton(
      onPressed: () => _handleGoogleSignIn(context),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        side: BorderSide(color: Colors.grey.shade300),
        backgroundColor: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/google_logo.png',
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Masuk dengan Google',
            style: AppTextStyle.headline3.copyWith(
              color: AppColors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
