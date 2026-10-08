import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

Widget buildWebGoogleSignInButton({
  required bool isLoading,
  required ValueChanged<GoogleSignInAccount> onAuthenticated,
  required ValueChanged<Object> onError,
}) =>
    throw UnsupportedError(
        'The Google Sign-In button is only available on web.');
