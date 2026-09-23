# PIL-227: activity history, RED phase

Source: https://linear.app/pilah-2/issue/PIL-227/halaman-daftar-riwayat-aktivitas-nasabah

The ticket has no description. Parent PIL-151 requires access to customer history
after login and active membership. The tests define proposed Indonesian labels,
loading, empty, error/retry, decimal rupiah formatting, and explicit pagination.
These labels and the load-more interaction are implementation assumptions, not
additional acceptance criteria copied from Linear.

The user requested RED only. `RiwayatNasabahPage` is a compiling empty page seam;
it is deliberately not routed into the app or connected to the network. The
loader will bind the authenticated membership in the GREEN phase. Do not replace
the tests with skipped tests or hard-coded fixture content.

Backend dependency: `feature/pil-225` at `31afd08` already supplies
`GET /api/v1/nasabah/me/riwayat` with `page`, `page_size`, and optional
`keanggotaan_id`. Response: `count`, `next`, `previous`, and `results`, containing
`id`, `tanggal`, `tipe`, and decimal-string `total_nilai`. Results are ordered by
descending date and ID and scoped to an active membership owned by the caller.
This contract currently contains setoran transactions. Separate pencairan work
exists on PIL-176/PIL-222 and is not represented as a unified activity feed here.

Validation on Flutter 3.41.3:

- `flutter pub get`
- `dart run build_runner build --delete-conflicting-outputs`
- `flutter analyze`: no issues.
- `flutter test --reporter expanded`: 215 passed, exactly 5 intentional assertion
  failures in `riwayat_nasabah_page_test.dart`; no compilation failures.

The analyzer 7.7.1 override reuses PIL-225's Freezed 2.x compatibility bridge.
Without it, the baseline's dependency constraints do not resolve on this SDK.
Generated sources, `.env`, and test logs remain local.
