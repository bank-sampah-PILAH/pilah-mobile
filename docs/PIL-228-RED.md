# PIL-228: role navigation, RED phase

## GREEN implementation

The follow-up request supersedes the RED-only checkpoint below. `RoleNavigationBar`
is now a reusable presentation component. `MainPage` maps its four visible tabs
to the correct StatefulShellRoute branches: customers use home/history/bank/profile,
while pengelola and pengelola_induk use dashboard/customers/prices/reports.
Staff profile keeps its standalone appearance. Unsupported and signed-out sessions
cannot inherit the staff navigation or its content; superadmin retains its own flow.
Changing supported roles resets the selected branch to home.

History and bank tabs use the existing authenticated repository. Direct history
entry resolves active membership through the API and offers its multi-bank choices
when required. Explicit membership links remain supported. The bank tab reuses
the existing public bank details fields. Profile stays read-only. Session keys
discard old customer responses after switching accounts. Customer links to staff
transaction routes redirect before loading those screens. Invite routing retains
priority over normal navigation guards; backend permissions remain authoritative.

TDD: reproduced the original five RED failures, added failing real-route tests,
then added and fixed the role-change regression. All eight navigation tests pass,
including staff compatibility and selected-tab behavior. The complete suite passes
269 tests; one pre-existing live-API test is skipped without its disposable fixture.
Backend dependency integration passes 80 tests. Commands: `flutter analyze --no-pub`,
`flutter test --no-pub --reporter expanded`, and `python manage.py test`.

PIL-227 is merged as a dependency so customer navigation reaches the implemented
paginated history page. The following text records the original RED checkpoint.

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
