# PILAH Mobile Instructions

## Scope

- This repository is the `pilah-mobile` application submodule of the PILAH
  workspace.
- Keep mobile implementation changes here, not in the workspace root or the
  backend repository.
- Keep the canonical checkout on `staging`; use `staging` as the worktree
  baseline and pull request target unless the request explicitly names another
  branch. Never infer `main` as the baseline.

## Development

- This project uses Flutter 3.41.3 and Dart 3.11.1.
- Add local environment values from `.env.example` before running the app.
- Run `flutter pub get` and the documented code generation command when
  generated sources are needed.

## Validation

- Run `flutter analyze`.
- Run `flutter test`.
- For mobile code changes, also build the Android debug APK with
  `flutter build apk --debug` and the web release with
  `flutter build web --release`.
- For web UI changes, use Playwright to QA both a desktop-sized browser and a
  mobile-sized browser viewport. Mobile viewport emulation checks responsive
  web UI only; it does not verify native mobile behavior.
- Web UI is supported only for Super Admin, Pengurus, and Pengurus Induk. Do
  not describe or imply Nasabah web support.
- For UI changes, save proof screenshots locally under
  `artifacts/pr-<PR_NUMBER>/`. Skip screenshots for non-UI changes, and do not
  commit screenshots or other artifacts. In the PR description, say when UI
  screenshots do not apply.
- Do not commit `.env`, Firebase credentials, build output, or generated local
  runtime files.

## Delivery

- For Linear-linked work, use `feature/<issue-id>` with the lowercase issue
  identifier, for example `feature/eng-123`.
- Use the local `.agents/skills/ship` skill with the global `ship` workflow for
  feature or fix branches in sibling `pilah-mobile-worktrees` directories.
- Use the local `.agents/skills/lgtm` skill with the global `lgtm` workflow for
  merge and cleanup.
- Keep the canonical checkout's detached submodule worktree untouched; make
  changes, commits, pushes, and PRs from the designated sibling worktree.
