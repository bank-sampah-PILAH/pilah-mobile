# PIL-536 TDD evidence

Baseline: `origin/staging` at `ed4004a5`; branch: `feature/pil-536`.

## Cycle 1: open a read-only schedule detail

- RED command: `flutter test --no-pub test/core/router/nasabah_schedule_detail_test.dart --reporter expanded`
- Actual RED: tapping the schedule left the agenda open; expected one `Detail Jadwal` text, found zero. One test failed.
- Setup failures (missing generated models and a missing shell provider fixture) were corrected before this demonstrated RED; they are not counted as RED evidence.
- GREEN: the detail route fetches the schedule through the existing authenticated, membership-scoped endpoint, shows its information without management actions, and returns to the selected agenda date.
- GREEN command: `flutter test --no-pub test/core/router/nasabah_schedule_detail_test.dart test/features/jadwal test/features/main/role_destinations_test.dart --reporter expanded` — 180 passed.

## Cycle 2: unavailable schedule links

- RED command: `flutter test --no-pub test/features/jadwal/presentation/pages/nasabah_jadwal_detail_page_test.dart --reporter expanded`
- Actual RED: an HTTP 404 showed a generic load error; expected `Jadwal tidak tersedia.`, found zero. One test failed.
- GREEN: HTTP 403/404 uses an unavailable message without exposing server details.
- GREEN command: `flutter test --no-pub test/core/router/nasabah_schedule_detail_test.dart test/features/jadwal/presentation/pages/nasabah_jadwal_detail_page_test.dart --reporter expanded` — 2 passed.

## Cycle 3: desktop customer agenda

- RED command: `flutter test --no-pub test/features/jadwal/presentation/pages/jadwal_customer_view_test.dart --plain-name "wide customer agenda reuses the web header and side calendar" --reporter expanded`
- Actual RED: the 1440-pixel customer schedule page had no `AppPageHeader`; expected one, found zero. One test failed.
- GREEN: customer schedules reuse the existing header, calendar, stacked/side-by-side agenda and empty state; customer requests remain day-scoped and have no staff actions.
- GREEN command: `flutter test --no-pub test/features/jadwal test/core/router/nasabah_schedule_detail_test.dart --reporter expanded` — 174 passed.

## Cycle 4: desktop Nasabah profile

- RED command: `flutter test --no-pub test/features/profile/presentation/pages/profil_nasabah_web_test.dart --reporter expanded`
- Actual RED: `ProfilePage(isWeb: true)` still used the phone profile; expected one `AppPageHeader`, found zero. One test failed.
- GREEN: web profile reuses `AppPageHeader` and `ContentFrame`, keeps the scroll area at the window edge, and retains the existing profile form and legal content.
- GREEN used all Nasabah profile test files plus legal tests — 35 passed. PowerShell command:

  ```powershell
  $nasabahTests = @(Get-ChildItem test/features/profile/presentation/pages/profil_nasabah*_test.dart | ForEach-Object FullName)
  flutter --no-version-check test --no-pub @nasabahTests test/features/legal test/core/router/legal_routes_test.dart --reporter expanded
  ```
- The broader profile suite reported two staff-logo filename failures on Windows; these are tracked separately from this focused GREEN result.

## Cycle 5: overnight schedule date

- RED command: `flutter test --no-pub test/features/jadwal/presentation/pages/nasabah_jadwal_detail_page_test.dart --plain-name "a schedule spanning midnight shows its end date" --reporter expanded`
- Actual RED: an overnight schedule showed its start date and both times but omitted the end date; expected `21/11/2026`, found zero. One test failed.
- GREEN: a separate end date appears only when the activity crosses a local calendar day.
- GREEN command: `flutter test --no-pub test/core/router/nasabah_schedule_detail_test.dart test/features/jadwal/presentation/pages/nasabah_jadwal_detail_page_test.dart --reporter expanded` — 3 passed.

## Regression checks after GREEN

These checks cover reused behavior; they are not claimed as additional demonstrated RED cycles.

- Web profile saves all five editable fields at 390 and 1440 logical pixels. The HTTP fixture receives the expected PATCH body without email, id, or role; reopening fetches the saved values.
- Web validation errors retain the draft and allow correction and retry, using the same form and validation response handling as mobile.
- The profile opens the existing legal page and returns correctly.
- Direct schedule links fetch fresh detail data with the authenticated API client and require no router extras.
- Existing schedule tests cover published-only customer presentation, empty days, paging, date navigation and read-only actions. Existing profile tests cover date selection, cancellation, failures and session changes.
- `flutter test --no-pub test/features/profile/presentation/pages/profil_nasabah_web_test.dart --reporter expanded` — 4 passed.
- `flutter test --no-pub test/features/profile/presentation/pages/profil_nasabah_edit_test.dart --reporter expanded` — 12 passed.

## Full validation

- `flutter --no-version-check analyze --no-pub` — no issues.
- `flutter --no-version-check test --no-pub --reporter expanded` — 3703 passed, 1 skipped, 2 failed. Both failures are existing Windows staff-logo filename expectations:
  - `profile_photo_upload_test.dart`: expected `logo.png`, actual `blob:http://localhost/logo.png`.
  - `profile_page_test.dart`: expected `profile_page_logo.jpg`, actual `Temp/profile_page_logo.jpg`.
  - Both failures were reproduced with staging's unchanged `ProfilePage` temporarily restored. The issue implementation was restored immediately afterward; no staff-logo code was changed.
- `flutter --no-version-check build apk --debug --no-pub -t lib/main_development.dart` — passed with process-local `GRADLE_OPTS=-Dorg.gradle.java.home=C:/Users/Omen/.jdks/ms-21.0.10`. The default installed Java 25 failed Gradle plugin resolution; no global tooling settings were changed.
- `flutter --no-version-check build web --release --no-pub --no-wasm-dry-run -t lib/main_development.dart` — passed (88.8 seconds). This validates the normal JavaScript release; Flutter's optional WebAssembly compatibility dry run was stopped and is not claimed as validated.
- An additional `flutter test --platform chrome` run stalled at suite loading and was stopped; it is not reported as passing.
- Playwright browser QA used production routes and synthetic HTTP fixtures at 1280×720 and 390×844: schedule list/detail, selected-day return, direct-detail refresh, unavailable and empty states, profile layout/editing, and legal navigation. Screenshots remain outside the repository.
- Backend code was unchanged. The existing schedule list/retrieve queryset was reviewed: it restricts Nasabah reads to active, approved bank memberships, published schedules that have not ended, and eligible recipients. This frontend change reuses that server enforcement.

## Coverage follow-up

- Added one focused regression for `pencairan`: the detail displays `Pencairan Saldo` instead of the wire value or the penimbangan label, without an edit action. It passed before the next test was added.
- Added a separate regression for an unknown activity type: the detail preserves the server-provided label instead of misclassifying it as penimbangan or pencairan, without an edit action.
- `flutter --no-version-check test --no-pub test/features/jadwal/presentation/pages/nasabah_jadwal_detail_page_test.dart --reporter expanded` — 4 passed.
- These cover existing behavior and are not claimed as demonstrated RED cycles. Application code, coverage exclusions, and existing assertions were unchanged.
- `flutter --no-version-check analyze --no-pub` after adding these tests — no issues.
- Fresh coverage command: `flutter --no-version-check test --no-pub --coverage --coverage-path coverage/pil-536-lcov.info --reporter expanded` — 3705 passed, 1 skipped, and the same 2 previously confirmed Windows staff-logo filename failures.
- Intersecting that fresh LCOV report's executable lines with added `lib/` lines in `git diff --unified=0 origin/staging -- lib` gives **100/100 covered new executable lines (100%)**, up from 98/100. `nasabah_jadwal_detail_page.dart` is now 46/46 (100%). No executable new lines remain uncovered.
- This is local added-line coverage against baseline `ed4004a5`, not a SonarCloud `new_coverage` result. Official SonarCloud metrics still require a branch/PR analysis.

## SonarQube cognitive-complexity follow-up

- SonarCloud PR #268 reported `dart:S3776` on `NasabahJadwalDetailPage.build`: cognitive complexity 19, above the allowed 15. The deeply nested activity-label switch and conditional detail rows contributed to that score.
- Extracted the unchanged schedule-information card into a private `_ScheduleDetails` stateless widget. Authentication, request loading, safe error messages, and the session-sensitive resource key remain in the page; the labels, dates, notes, layout, and read-only behavior are unchanged.
- This is a necessary behavior-preserving refactor after GREEN, not a new RED cycle. Existing detail and routing regressions passed: `flutter --no-version-check test --no-pub test/features/jadwal/presentation/pages/nasabah_jadwal_detail_page_test.dart test/core/router/nasabah_schedule_detail_test.dart --reporter expanded` — 5 passed.
- `flutter --no-version-check analyze --no-pub` — no issues.
- `flutter --no-version-check build apk --debug --no-pub -t lib/main_development.dart` — passed with process-local JDK 21 selection.
- `flutter --no-version-check build web --release --no-pub --no-wasm-dry-run -t lib/main_development.dart` after the extraction — passed.
- Fresh full-suite coverage after the extraction: 3705 passed, 1 skipped, and the same 2 confirmed Windows staff-logo filename failures. Added-line coverage against `origin/staging` remains **100/100 (100%)**, with 46/46 covered lines in the detail page.
