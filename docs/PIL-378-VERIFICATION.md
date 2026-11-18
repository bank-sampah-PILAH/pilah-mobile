# PIL-378 verification record

## Linear issue placement and ordering

Live Linear MCP responses and the goal task history record:

| Fact | Value | Source |
| --- | --- | --- |
| Issue | [PIL-378](https://linear.app/pilah-2/issue/PIL-378/perbaiki-layout-form-authoring-announcement-di-web) | `linear_get_issue` |
| Created at | `2026-10-22T06:49:37.354Z` | Linear `createdAt` field |
| Parent | [PIL-143 — CPBI-15](https://linear.app/pilah-2/issue/PIL-143/cpbi-15-siklus-announcement-authoring-publikasi-dan-pembacaan) | Linear `parentId` and parent issue query |
| Cycle | Sprint 2 (`42eed940-98b2-455b-b1f3-9186141719a2`) | Linear `cycleId`; `linear_list_cycles` resolves the ID to Sprint 2 |
| Project | EPIC07 — Communication & Notifications | Linear `project` field |
| Assignee | None | Linear `assigneeId: null` |

The goal history records the `implement-ui` task starting at
`2026-10-22T06:49:47.418Z`, 10.064 seconds after the Linear `createdAt` value.
The first branch commit is [97696a9](https://github.com/bank-sampah-PILAH/pilah-mobile/commit/97696a9ec1cd1a941ab086ea0d8a4a212bf1f2b1),
committed at `2026-10-22T13:58:18+07:00` (06:58:18Z), after both.

The selected Linear MCP fields are also available as
[machine-readable JSON](../artifacts/pr-156/linear-placement.json).

## Implementation and delivery

- Feature branch: `feature/pil-378`
- Worktree: `/home/tray/Projects/kuliah/pilah-mobile-worktrees/feature-pil-378`
- Head: `1e5ea83be16b401ed8cd80613f8398b167b71e37`
- PR: [#156 — feat: tampilkan form pengumuman di panel kanan](https://github.com/bank-sampah-PILAH/pilah-mobile/pull/156)
- Target: `staging`; state: open

The expanded web layout opens the announcement form in a right-side panel while
keeping the list visible. Small web layouts and native mobile retain the
route-based form. Jadwal-style visible labels are present for the form fields.
Existing validation, draft saving, scheduling, and publication behavior is
preserved; no backend changes were made.

## Validation

Local commands completed successfully:

```sh
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter analyze
fvm flutter test
fvm flutter build apk --debug -t lib/main_development.dart
fvm flutter build web --release -t lib/main_development.dart
```

The full Flutter suite reported 2,681 passed and one skipped. Android emulator
smoke verification opened the Pengurus demo and checked the phone-sized form
and labels using a local API stub. Playwright profile-mode verification used
the same demo API at 1440x900 and 390x844: desktop showed the side panel beside
the list; the mobile-sized web layout retained route navigation. The two
screenshots are attached to PR #156.

GitHub checks for the PR head above:

- [Format, analyze, tests & build — pass](https://github.com/bank-sampah-PILAH/pilah-mobile/actions/runs/39774349589/job/119809426246)
- [SonarCloud analysis — pass](https://github.com/bank-sampah-PILAH/pilah-mobile/actions/runs/39774349558/job/119809426150)
- [SonarCloud Code Analysis — pass](https://sonarcloud.io/dashboard?id=bank-sampah-PILAH_pilah-mobile&pullRequest=156)
- PR-only APK artifact and staging deploy jobs were skipped by the workflow.
