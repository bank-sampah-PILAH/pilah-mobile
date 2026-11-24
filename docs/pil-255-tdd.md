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
