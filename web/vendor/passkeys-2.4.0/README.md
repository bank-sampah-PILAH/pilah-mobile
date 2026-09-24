# Passkeys Web SDK

Source: https://github.com/corbado/flutter-passkeys/releases/download/2.4.0/bundle.js
Version: 2.4.0, explicitly required by the installed passkeys_web 2.9.0 plugin.
The bundle is unmodified. See LICENSE for the upstream license.

Flutter registers this plugin before the Dart entrypoint, even for the visual
preview. Load this local script before flutter_bootstrap.js to prevent the
plugin from closing the browser window. Do not add async/defer to this script
without also coordinating the Flutter bootstrap order.
