import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as google_sign_in_web;
import 'package:pilah_mobile/design/constants/colors.dart';

Widget buildWebGoogleSignInButton({
  required bool isLoading,
  required ValueChanged<GoogleSignInAccount> onAuthenticated,
  required ValueChanged<Object> onError,
  @visibleForTesting
  Stream<GoogleSignInAuthenticationEvent>? authenticationEvents,
  @visibleForTesting Widget Function()? buttonBuilder,
}) =>
    _WebGoogleSignInButton(
      isLoading: isLoading,
      onAuthenticated: onAuthenticated,
      onError: onError,
      authenticationEvents: authenticationEvents,
      buttonBuilder: buttonBuilder,
    );

class _WebGoogleSignInButton extends StatefulWidget {
  final bool isLoading;
  final ValueChanged<GoogleSignInAccount> onAuthenticated;
  final ValueChanged<Object> onError;
  final Stream<GoogleSignInAuthenticationEvent>? authenticationEvents;
  final Widget Function()? buttonBuilder;

  const _WebGoogleSignInButton({
    required this.isLoading,
    required this.onAuthenticated,
    required this.onError,
    this.authenticationEvents,
    this.buttonBuilder,
  });

  @override
  State<_WebGoogleSignInButton> createState() => _WebGoogleSignInButtonState();
}

class _WebGoogleSignInButtonState extends State<_WebGoogleSignInButton> {
  late final StreamSubscription<GoogleSignInAuthenticationEvent>
      _authenticationSubscription;

  @override
  void initState() {
    super.initState();
    _authenticationSubscription = (widget.authenticationEvents ??
            GoogleSignIn.instance.authenticationEvents)
        .listen(
      _onAuthenticationEvent,
      onError: (Object error) {
        if (mounted) widget.onError(error);
      },
    );
  }

  void _onAuthenticationEvent(GoogleSignInAuthenticationEvent event) {
    if (!mounted) return;
    if (event case GoogleSignInAuthenticationEventSignIn(:final user)) {
      widget.onAuthenticated(user);
    }
  }

  @override
  void dispose() {
    unawaited(_authenticationSubscription.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.greenDark),
      );
    }

    return Center(
      child: widget.buttonBuilder?.call() ??
          google_sign_in_web.renderButton(
            configuration: google_sign_in_web.GSIButtonConfiguration(
              theme: google_sign_in_web.GSIButtonTheme.outline,
              size: google_sign_in_web.GSIButtonSize.large,
              text: google_sign_in_web.GSIButtonText.signinWith,
              locale: 'id',
            ),
          ),
    );
  }
}
