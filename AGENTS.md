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
  `GOOGLE_SERVER_CLIENT_ID` must be a Web OAuth client ID with authorized
  JavaScript origins for local and deployed hosts; pass it as web's `clientId`
  and native's `serverClientId`.
- Android builds also require ignored `android/app/google-services.json`.
  CI materializes it from the `GOOGLE_SERVICES_JSON` secret; use an authorized
  local Firebase config, never log or commit it, and ask a maintainer to
  provision it if missing.
- Run `flutter pub get` and the documented code generation command when
  generated sources are needed.
- Commit `lib/services/di.config.dart` exactly as `build_runner` writes it; CI
  and the CD workflows regenerate it, so a hand-edited copy hides what ships.
  Add every new injectable registration to
  `test/services/di_registrations.dart`. `di_graph_test` resolves each one in
  dev and prod, and fails when the list and the generated file disagree.

- For quick iteration, run the affected test file with
  `flutter test test/path/to/feature_test.dart`, or one named test with
  `flutter test test/path/to/feature_test.dart --plain-name "test description"`.
  Before shipping, run full `flutter analyze` and `flutter test`; mobile changes
  also need the Android debug APK and web release builds listed below. PRs and
  feature-branch pushes run only changed VM test files under `test/` (none when
  none changed) plus the sibling `test/` mirrors of any changed `lib/` source
  file, with browser tests only for web-code or browser-test diffs.
  Pushes to `staging` run the full sharded Flutter and browser suites. After LCOV
  merge, the existing 25% global and diff-coverage gates run only on `staging`;
  diff coverage compares the push with its previous SHA. Sonar reuses same-run
  coverage when available and never reruns tests.

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
  not describe or imply Nasabah web support. Current web entrypoints skip
  Firebase initialization because no web-supported flow uses Firebase; add
  FlutterFire web options before introducing a Firebase-backed web flow.
- For user-visible Flutter web UI changes, capture Playwright screenshots for
  affected supported roles and viewports. Before the PR number exists, keep
  captures outside the repository; afterwards they may sit under
  `artifacts/pr-<PR_NUMBER>/`. Never commit them. Skip screenshots for non-UI
  changes, and say in the PR description when UI screenshots do not apply.
- Put PR screenshots in the PR description with `gh image`, which uploads to
  GitHub `user-attachments`; follow the "Upload screenshots" step of the
  `ship` skill. The
  repository is public, so screenshots must show demo data only. If `gh image`
  cannot be used, fall back to an orphan branch `pr-<PR_NUMBER>-screenshots`
  and never delete that branch, since doing so breaks the images in the PR.
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
- Read `DESIGN.md` before adding or changing any Flutter UI.
