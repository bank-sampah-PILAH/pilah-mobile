# Play Store release process

## Android identity and version

- Keep the application ID `com.mobile.pilahapp`; it is the identity of the existing Play app.
- `pubspec.yaml` uses `MAJOR.MINOR.PATCH+BUILD`. The planned release is `2.0.0+7`, so its tag is `v2.0.0`. Play Console currently shows version code 6 as the highest uploaded bundle.
- Before creating the tag or uploading, recheck Play Console's highest version code and set `+BUILD` to a greater value. The workflow only enforces the known rejected-code lower bound of 6; it cannot query Play's latest version. Match the tag to the version name. Never reuse a version code or move an existing release tag.
- Keep the existing upload key and Play App Signing configuration. Do not generate or rotate an upload key as part of a release.

## Required GitHub configuration

Protect the `production` environment with an approval reviewer. Store the signing, production app configuration, and Play service account values below as `production` environment secrets; do not put secret values in the repository, issue tracker, or release notes:

- `APP_ENV_FILE`: must include `BASE_URL_PROD` (an HTTPS production API origin) and `GOOGLE_SERVER_CLIENT_ID` (the Web OAuth client ID). The release workflow calls `scripts/prepare_web_env.py`, which validates and writes only those production values plus `ENABLE_DEMO_LOGIN=false` to the bundled `.env` asset.
- `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, and `ANDROID_KEYSTORE_PASSWORD`: the existing Play upload key and its credentials.
- `GOOGLE_SERVICES_JSON`: the production Firebase configuration. The workflow checks that it includes `com.mobile.pilahapp`.
- `PLAY_TEST_SERVICE_ACCOUNT_JSON`: a service account limited to the PILAH app's testing tracks.
- `PLAY_PRODUCTION_SERVICE_ACCOUNT_JSON`: a separate service account limited to the PILAH app's production release permission.

Store `SONAR_TOKEN` as a repository Actions secret with permission to run the mobile project scan. The tag verification job intentionally does not use the protected `production` environment, so the repository-scoped secret is available without production-environment approval.

The production seed creates PILAH users for the review roles, but it does not create their Google accounts or passwords. Do not put Google account credentials in backend configuration, `APP_ENV_FILE`, Firebase configuration, a Dart define, an asset, or GitHub release metadata.

## Build and test track upload

Push a `vMAJOR.MINOR.PATCH` tag whose version matches `pubspec.yaml`. The workflow runs Flutter analysis, tests, the coverage gate, and SonarCloud's quality gate before it prepares production configuration, signs the AAB, and uploads that AAB to the closed Alpha track. The GitHub Release stores that exact AAB, its SHA-256 file, and the source commit/build metadata.

The workflow fails before building if required production configuration or signing secrets are absent, if the production API URL is not HTTPS, if the Firebase package does not match, or if the tag/version do not match. It refuses to overwrite an existing GitHub Release.

## Reviewer access and policy resubmission

The PILAH production seed provides these isolated review accounts and fixtures:

- Pengelola: `traymachi@gmail.com`, owner of the active synthetic demo bank.
- Pengurus: `pilah.pengurus@gmail.com`.
- Nasabah: `pilah.nasabah@gmail.com`, with synthetic transaction history, catalog, schedules, and balance.
- Superadmin: `pilah.superadmin@gmail.com`, restricted to the synthetic pending bank and its approval flow.

Before submitting or resubmitting, confirm each Google account exists and can sign in on a clean device without a device-bound challenge. In Play Console's App access / Sign in details, provide the reusable account credentials and concise role-specific steps for reaching the features under review. The credentials must be available to Google reviewers; do not put them in this repository, Linear, release notes, or screenshots. Submit the corrected build and access instructions for review, then record the outcome, affected version, and sanitized evidence in the QA and production-access tracking issues.

The Play Console dashboard currently reports that this app has production access, so no 12-testers-for-14-days wait is pending for this release. Apply that eligibility requirement only if Play Console shows it for a future account or app state.

## Retry and production promotion

Use the `CD - Production` workflow's manual dispatch with an existing release tag to retry a track assignment or promote its exact AAB. It downloads the AAB, checksum, and build metadata, verifies their identity, and checks Google Play's bundle list for the same version code and SHA-256. It then updates that track to the already uploaded version code and commits the edit; it does not upload a second bundle or rebuild. If the exact version code and digest are not already present in Play, the dispatch fails before changing a track. In that case, create a new patch version and version code for a replacement build. Select `production` only after Google has approved the release and confirm the approval input. The protected `production` environment supplies an additional human approval gate. The API refuses to commit while another app change is in review rather than cancelling and resubmitting that review.

If a track assignment fails after the bundle is registered in Play, fix the access/configuration problem and dispatch the same release tag again. A dispatch cannot recover an upload that never registered the bundle in Play because it deliberately does not upload bundles. Do not create another tag for the same version code. If the app needs a code fix, create a new patch version and version code, then run the checks and upload a new AAB.

If a production rollout needs to stop, halt it in Play Console and document the decision and recovery owner.
