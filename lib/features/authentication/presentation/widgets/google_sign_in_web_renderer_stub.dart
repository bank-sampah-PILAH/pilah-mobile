import 'package:flutter/material.dart';

// Chrome tests exercise the real renderer and guard this stub's API shape.
enum GSIButtonTheme { outline }

enum GSIButtonSize { large }

enum GSIButtonText { signinWith }

class GSIButtonConfiguration {
  GSIButtonConfiguration({
    this.theme,
    this.size,
    this.text,
    this.locale,
  });

  final GSIButtonTheme? theme;
  final GSIButtonSize? size;
  final GSIButtonText? text;
  final String? locale;
}

Widget renderButton({GSIButtonConfiguration? configuration}) =>
    GoogleSignInWebRendererStub(configuration: configuration);

class GoogleSignInWebRendererStub extends StatelessWidget {
  const GoogleSignInWebRendererStub({super.key, required this.configuration});

  final GSIButtonConfiguration? configuration;

  @override
  Widget build(BuildContext context) =>
      const SizedBox(key: ValueKey('google-sign-in-web-renderer-stub'));
}
