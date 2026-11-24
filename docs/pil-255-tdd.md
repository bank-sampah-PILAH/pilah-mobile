# PIL-255 TDD evidence

Branch: `feature/pil-255`. Baseline: cached `origin/staging` at `ed4004a5`;
fetch failed with SSH host key verification. No canonical checkout changes.

1. Owned roles: RED expected `[pengelola, nasabah]`, actual `[nasabah]`.
   GREEN: owned-role test and mapper regressions, 4 passed.

Logs from each command are ignored `cycle-*-red.log` / `cycle-*-green.log`
in this worktree. Initial generator/setup failures were not counted as RED.

2. Coordinator ordering: RED expected nasabah, actual pengelola. GREEN: both directions persist -> reset -> publish -> observe; 2 tests passed.

3. Selection guards: RED expected 0 requests, actual 2. GREEN: coordinator suite 2 passed.

4. Duplicate taps: RED expected 1 request, actual 2. GREEN: coordinator suite 3 passed.

5. Connection failure: RED unhandled TimeoutException. GREEN: old session untouched, error observed, coordinator suite 4 passed.

6. Invalid responses: RED expected 0 mutations, actual 3. GREEN: wrong role/account, missing tokens and unsafe routing hints rejected; 5 tests passed.

7. Logout race: RED expected 0 mutations, actual 3. GREEN: late switch response discarded; 6 tests passed.

8. HTTP integration: RED switch request unimplemented. GREEN: real HTTP stack POST contract and coordinator regressions, 7 passed.

9. Storage failure: RED expected storage error, operation completed. GREEN: one secure record written before memory changes; coordinator/store suite 7 passed.

10. Restart: RED expected new-access, actual legacy-access. GREEN: single-record restore and auth storage/repository regressions, 16 passed.

11. Logout: RED restored new-access after logout. GREEN: switched and legacy session removal, 7 passed.

12. Later login: RED restored switched token rather than login token. GREEN: auth repository/storage regressions, 18 passed.

13. Login roles: RED expected both roles, actual pengelola only. GREEN: login/restore/mapper/HTTP regressions, 6 passed.

14. Switch-back eligibility: RED response lost pengelola ownership. GREEN: coordinator and role mapping, 9 passed.

15. Late data: RED old-role private response delivered. GREEN: stale responses cancelled plus network/HTTP regressions, 17 passed.

16. Credential logs: RED bearer and returned tokens visible in synthetic logs. GREEN: authorization headers and auth bodies redacted; 16 network tests passed.

17. Profile controls: RED Role saya missing. GREEN: both-role widget interactions and coordinator regressions, 8 passed.

18. Profile integration: RED Role saya absent from real profile. GREEN: 65 profile/widget tests passed; excluded existing Windows logo filename mismatch pending baseline confirmation.

19. Cache integration: RED old private WhatsApp template visible when new role published. GREEN: real HTTP/store/auth/cache flow and coordinator/storage regressions, 12 passed.

20. Navigation observer: RED pending-approval destination missing. GREEN: observer, real switch integration and App session-reset regressions, 4 passed.

21. Failure observer: RED expected one error notification, actual none. GREEN: navigation/error observer and coordinator tests, 9 passed.

22. Keystore/logout race: RED pending save completed after logout. GREEN: session revision invalidates pending write and publication; 15 coordinator/store/integration/observer tests passed.

Staging integration: HTTPS fetch succeeded; merged origin/staging df5eef02 after resolving auth, profile, network and App conflicts. Merge regression suite: 12 passed. Backend stays unchanged by user instruction; owned roles must be exposed in login and /auth/me before this switcher can offer a second role.

23. Current staging primary-pengurus field: RED flag became false during owned-role copy. GREEN: coordinator and role mapping suite, 10 passed.

24. Stale removal error: RED old-role 403 reached removal handling. GREEN: stale response/error and current-session removal regressions, 26 passed.


## Backend prerequisite (mobile-only scope)

The user explicitly chose to keep PIL-255 mobile-only. No backend changes are
included. PIL-251/PIL-540 must expose the account's owned `roles` in the login
`user` object and the flat `/api/v1/auth/me` response. The inspected backend
snapshots have `roles` internally but omit it from those serializers/responses.
Until this is provided, legacy payloads show only the active role and no switch
action. The client never invents role ownership.

PIL-540 must provide `POST /api/v1/auth/switch-role` with `{ "role": "nasabah" }`
or `{ "role": "pengelola" }`, returning `access_token`, `refresh_token`, `user`
and a role-appropriate `next_step`. The active role is scoped to those tokens;
server-side authorization, refresh continuity and device independence remain
backend responsibilities. PIL-543 owns adding a role; this change supplies the
shared profile switching section and does not implement role acquisition.

## Design and security boundaries

The coordinator validates the response, persists the token pair in one secure
record, resets role-dependent state, and then publishes authentication. Riverpod
observers handle rendering, navigation and error feedback. Loading/failure does
not replace the authenticated session with an unauthenticated/loading state.

Controls include owned-role selection guards, account/role/next-step response
validation, duplicate-request prevention, previous-token response/error rejection,
logout/write race protection, and credential redaction in network logs. Existing
platform secure storage is used; changing web authentication to HttpOnly cookies
or a BFF requires backend work and is outside this mobile-only change.

## Broader regression checks

Supplemental HTTP integration cases (403, 500, connection timeout and malformed
2xx payload) were added after implementation and passed. They are regression
coverage, not additional demonstrated RED cycles.

After the broad run, the Nasabah role section was placed below personal details
so existing edit controls remain in place; reachability is tested by scrolling.
The legacy storage mock now supplies null for optional unknown records. These
corrections and the affected profile/edit/storage tests passed (55 tests).

Two logo filename failures reproduce on an untouched archive of current staging:
`profile_photo_upload_test.dart` (blob filename) and `profile_page_test.dart`
(Windows temporary-path filename). Their implementations are unchanged here.


## Final validation

- `flutter analyze --no-pub`: no issues.
- Focused PIL-255 tests (9 files): 24 passed.
- Affected Nasabah profile/edit and legacy storage regressions: 55 passed.
- `flutter test --no-pub --reporter expanded`: 3,949 passed, 1 skipped,
  2 failed. Both failures are the logo filename cases reproduced on untouched
  `origin/staging` above; no feature test failures remain.
- `flutter build web --release --no-pub -t lib/main_development.dart`: passed.
- `flutter build apk --debug --no-pub -t lib/main_development.dart`: passed with
  `GRADLE_OPTS=-Dorg.gradle.java.home="C:/Program Files/Java/jdk-22"` scoped to
  the command. The initial machine-default JDK 25 attempt failed in Gradle.
- Browser QA used an ignored offline demo harness with the actual profile
  widgets, coordinator and root observer, with demo data only. Playwright
  interactions verified switching in both directions, disabled controls while
  pending, and navigation to the selected role's home. Screenshots captured
  Pengurus and Nasabah at 1440x1000 and 390x844; no browser errors observed.
  Captures are browser-session artifacts and were not committed.
- Browser QA used mocked backend responses; it does not establish live API
  compatibility or native device behavior. The backend prerequisite remains.

There are 24 demonstrated RED/GREEN cycles, with one RED test commit followed by
one passing implementation commit per cycle. Additional integration/regression
coverage is explicitly distinguished above. The issue branch also incorporates
current staging. No push or PR creation was requested.
