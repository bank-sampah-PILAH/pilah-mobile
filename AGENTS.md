# PILAH Mobile Instructions

## Scope

- This repository is the `pilah-mobile` application submodule of the PILAH
  workspace.
- Keep mobile implementation changes here, not in the workspace root or the
  backend repository.
- Use `staging` as the worktree baseline and PR target unless the request names
  another branch; never infer `main`. A standalone canonical checkout should
  remain on `staging`. When nested in the workspace, the submodule may be
  detached at the parent-pinned commit; leave it untouched and use a sibling
  worktree.

## Development

- This project uses Flutter 3.41.3 and Dart 3.11.1.
- Add local environment values from `.env.example` before running the app.
- Run `flutter pub get` and the documented code generation command when
  generated sources are needed.

## Validation

- For Flutter code or behavior changes, run `flutter analyze` and `flutter test`.
- For documentation-only changes, run `git diff --check` and configured
  documentation checks; skip Flutter commands.
- For mobile code changes, also build the Android debug APK with
  `flutter build apk --debug -t lib/main_development.dart` and the web release
  with `flutter build web --release -t lib/main_development.dart`.
- For web UI changes, use Playwright to QA both a desktop-sized browser and a
  mobile-sized browser viewport. Mobile viewport emulation checks responsive
  web UI only; it does not verify native mobile behavior.
- Web UI is supported only for Super Admin, Pengurus, and Pengurus Induk. Do
  not describe or imply Nasabah web support.
- For user-visible Flutter web UI changes, capture Playwright screenshots for
  affected supported roles and viewports under `artifacts/pr-<PR_NUMBER>/`.
  Skip screenshots for non-UI changes, do not commit artifacts, and say in the
  PR description when UI screenshots do not apply.
- Do not commit `.env`, Firebase credentials, build output, or generated local
  runtime files.

## Delivery

- For Linear-linked work, use `feature/<issue-id>` with the lowercase issue
  identifier, for example `feature/eng-123`.
- For changes spanning both backend and mobile, use the workspace
  `multi-ship` skill and keep the issue-derived branch name the same in each
  repository.
- Use the local `.agents/skills/ship` skill with the global `ship` workflow for
  feature or fix branches in sibling `pilah-mobile-worktrees` directories.
- Use the local `.agents/skills/lgtm` skill with the global `lgtm` workflow for
  merge and cleanup.
- Make changes, commits, pushes, and PRs from the designated sibling worktree.
