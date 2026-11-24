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
