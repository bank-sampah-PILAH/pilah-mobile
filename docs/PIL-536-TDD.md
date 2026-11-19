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
- GREEN command: `flutter test --no-pub <all test/features/profile/presentation/pages/profil_nasabah*_test.dart files> test/features/legal test/core/router/legal_routes_test.dart --reporter expanded` — 35 passed.
- The broader profile suite reported two staff-logo filename failures on Windows; these are tracked separately from this focused GREEN result.

## Cycle 5: overnight schedule date

- RED command: `flutter test --no-pub test/features/jadwal/presentation/pages/nasabah_jadwal_detail_page_test.dart --plain-name "a schedule spanning midnight shows its end date" --reporter expanded`
- Actual RED: an overnight schedule showed its start date and both times but omitted the end date; expected `21/11/2026`, found zero. One test failed.
- GREEN: a separate end date appears only when the activity crosses a local calendar day.
- GREEN command: `flutter test --no-pub test/core/router/nasabah_schedule_detail_test.dart test/features/jadwal/presentation/pages/nasabah_jadwal_detail_page_test.dart --reporter expanded` — 3 passed.
