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
