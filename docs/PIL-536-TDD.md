# PIL-536 TDD evidence

Baseline: `origin/staging` at `ed4004a5`; branch: `feature/pil-536`.

## Cycle 1: open a read-only schedule detail

- RED command: `flutter test --no-pub test/core/router/nasabah_schedule_detail_test.dart --reporter expanded`
- Actual RED: tapping the schedule left the agenda open; expected one `Detail Jadwal` text, found zero. One test failed.
- Setup failures (missing generated models and a missing shell provider fixture) were corrected before this demonstrated RED; they are not counted as RED evidence.
