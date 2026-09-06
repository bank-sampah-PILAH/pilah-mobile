# PILAH Mobile Instructions

## Scope

- This repository is the `pilah-mobile` application submodule of the PILAH
  workspace.
- Keep mobile implementation changes here, not in the workspace root or the
  backend repository.
- Keep the canonical checkout on `main`; use `staging` as the default worktree
  baseline and pull request target unless the request explicitly names another
  branch.

## Development

- This project uses Flutter 3.41.3 and Dart 3.11.1.
- Add local environment values from `.env.example` before running the app.
- Run `flutter pub get` and the documented code generation command when
  generated sources are needed.

## Validation

- Run `flutter analyze`.
- Run `flutter test`.
- Do not commit `.env`, Firebase credentials, build output, or generated local
  runtime files.

## Delivery

- Use the local `.agents/skills/ship` skill with the global `ship` workflow for
  feature or fix branches in sibling `pilah-mobile-worktrees` directories.
- Use the local `.agents/skills/lgtm` skill with the global `lgtm` workflow for
  merge and cleanup.
