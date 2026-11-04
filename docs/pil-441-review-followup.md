# PIL-441 reviewer follow-up

The Sonar `dart:S3776` finding is addressed by extracting current-request failure handling from `loadNasabah` into `_handleListFailure`. Existing cancellation state behavior is preserved: a current cancelled refresh retains rows and clears loading; a cancelled initial load returns to the initial state. Stale generations still return before state handling.

The domain repository and use case now accept a transport-independent `RequestCancellation`. It signals cancellation and retains the first reason; the data repository converts it to Dio's `CancelToken`. No `domain/**` file imports Dio. Integration tests exercise cancellation through the actual use case, repository, data source, and Dio with HTTP stubbed, including cancellation before dispatch and repeated cancellation.

Logout `reset()` cancels the list and active-count requests. Disposal cancels both, and a newer count refresh replaces the old count signal. Generation guards remain in place. The count request still asks for one row and uses the server's total count. Client cancellation does not promise to abort an already executing backend database query.

## Actual incremental TDD evidence

| Interaction | RED evidence | GREEN commit |
|---|---|---|
| Logout cancels the list request | `c823a056`: expected cancelled true, actual false | `b300c7a5` |
| Logout cancels an active-count refresh | `6d2df415`: expected cancelled true, actual false | `f3d700df` |

The Sonar extraction (`fae2c873`) and domain decoupling (`317f02b4`) are behavior-preserving refactors after GREEN, validated with the existing cancellation tests. Tests added after implementation are regression evidence, not claimed as RED cycles.

## Validation scope

The focused customer-feature and HTTP-client run passes 291 tests. Local line coverage for committed changed production lines is 49/49 (100%), excluding the unrelated uncommitted demo-menu edits. Analyzer is clean. Full-suite and Android/web build results are reported in PR #168 after those runs finish; the Sonar issue count must be checked on the new CI analysis rather than inferred from the quality-gate badge alone.

This follow-up does not change the visible search layout. The existing phone/web screenshots remain the feature evidence. Email search remains supported by the backend, while the hint lists name, ID, and phone; the two-character minimum is preserved. The backend separately rejects normalized queries longer than 100 characters with a field error.
