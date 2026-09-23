# PIL-228: role navigation, RED phase

Source: https://linear.app/pilah-2/issue/PIL-228/reusable-navigation-bar-berdasarkan-role

The ticket has no description. Parent PIL-151 requires customer navigation to
history and bank information. The proposed customer tabs are Beranda, Riwayat,
Bank Sampah, and Profil. Pengelola and pengelola_induk retain the current staff
tabs. Superadmin retains its separate flow; unknown and signed-out sessions
must not inherit the staff navigation. These menu choices are explicit design
assumptions for the next phase.

The user requested RED only. Tests exercise the existing production `MainPage`
with a real GoRouter shell and a mocked auth session. Route bodies are test
fixtures to isolate tab selection; they do not establish production URLs or
verify production route authorization. No navigation implementation was added.
GREEN should extract a reusable role-aware navigation component and integrate
it into the production shell, with role-change and route-guard tests.

Backend: existing `GET /api/v1/auth/me` returns the authoritative `role`.
PIL-225's dependency chain adds nasabah and pengelola_induk to the earlier
pengelola/superadmin roles. A separate navigation API is unnecessary. Hiding a
menu does not replace backend authorization.

Validation on Flutter 3.41.3:

- `flutter pub get`
- `dart run build_runner build --delete-conflicting-outputs`
- `flutter analyze`: no issues.
- `flutter test --reporter expanded`: 217 passed, exactly 5 intentional assertion
  failures in `role_navigation_test.dart`; the 2 staff regression tests pass.

The analyzer 7.7.1 pin reuses PIL-225's Freezed compatibility bridge, required
to resolve the baseline dependencies with this SDK. Generated files stay local.
