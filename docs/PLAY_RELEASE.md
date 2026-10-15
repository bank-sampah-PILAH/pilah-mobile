# Play Store release process

## Android identity and version

- Keep the application ID `com.mobile.pilahapp`; it is the identity of the existing Play app.
- `pubspec.yaml` uses `MAJOR.MINOR.PATCH+BUILD`. The current recovery build is `1.0.1+7`, after the rejected Play version code 6. The release tag must be `v1.0.1`.
- Before every later upload, check the highest version code already in Play Console and increment the `+BUILD` value. Match the tag to the version name. Never reuse a version code or move an existing release tag.
- Keep the existing upload key and Play App Signing configuration. Do not generate or rotate an upload key as part of a release.

## Required GitHub configuration

Protect the `production` environment with an approval reviewer. Store these values as environment secrets; do not put secret values in the repository, issue tracker, or release notes:

- `APP_ENV_FILE`: must include `BASE_URL_PROD` (an HTTPS production API origin) and `GOOGLE_SERVER_CLIENT_ID` (the Web OAuth client ID). The release workflow calls `scripts/prepare_web_env.py`, which validates and writes only those production values plus `ENABLE_DEMO_LOGIN=false` to the bundled `.env` asset.
- `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, and `ANDROID_KEYSTORE_PASSWORD`: the existing Play upload key and its credentials.
- `GOOGLE_SERVICES_JSON`: the production Firebase configuration. The workflow checks that it includes `com.mobile.pilahapp`.
- `PLAY_TEST_SERVICE_ACCOUNT_JSON`: a service account limited to the PILAH app's testing tracks.
- `PLAY_PRODUCTION_SERVICE_ACCOUNT_JSON`: a separate service account limited to the PILAH app's production release permission.
- `SONAR_TOKEN`: an analysis token with permission to run the mobile project scan.

Keep reviewer login credentials in backend production configuration only; store the password as a Django password hash. Do not add reviewer credentials to `APP_ENV_FILE`, Firebase configuration, a Dart define, an asset, or GitHub release metadata.

## Build and test track upload

Push a `vMAJOR.MINOR.PATCH` tag whose version matches `pubspec.yaml`. The workflow runs Flutter analysis, tests, the coverage gate, and SonarCloud's quality gate before it prepares production configuration, signs the AAB, and uploads that AAB to the closed Alpha track. The GitHub Release stores that exact AAB, its SHA-256 file, and the source commit/build metadata.

The workflow fails before building if required production configuration or signing secrets are absent, if the production API URL is not HTTPS, if the Firebase package does not match, or if the tag/version do not match. It refuses to overwrite an existing GitHub Release.

## Reviewer access and policy resubmission

The current Play rejection says reviewer credentials must not depend on device-bound authentication. Before resubmitting:

1. Provision the dedicated active `pengelola` reviewer account on a synthetic bank and enable reviewer login through the documented backend settings. Keep `DJANGO_DEBUG=false` and fake Google tokens disabled.
2. Install the exact Alpha-delivered build on a clean Android device or profile with no prior Google account/device trust. Verify reviewer login works, Google Sign-In still works for normal users, and disabling the backend flag hides the entry and rejects direct login attempts.
3. In Play Console's App access / Sign in details declaration, have the authorized operator enter the dedicated reviewer credentials and concise steps for reaching the features under review. Use a non-device-bound password login; do not put the credentials in this repository, Linear, release notes, or screenshots.
4. Submit the corrected build and access instructions for review. Record the outcome, affected version, and sanitized evidence in the QA and production-access tracking issues.
5. Before requesting production access, confirm the account's current closed-testing eligibility, then maintain at least 12 active testers opted in continuously for 14 days. If the count drops below 12, the waiting period may restart.

## Retry and production promotion

Use the `CD - Production` workflow's manual dispatch with an existing release tag to retry a test-track upload or promote its exact AAB. It downloads the release asset and verifies its SHA-256; it does not rebuild or change its version code. Select `production` only after Google has approved the release and confirm the approval input. The protected `production` environment supplies an additional human approval gate.

If a Play upload fails after the GitHub Release was created, fix the missing access/configuration and dispatch the same release tag again. Do not create a replacement tag for the same version code. If the app needs a code fix, create a new patch version and version code, then run the checks and upload a new AAB.

To disable reviewer entry during an incident, set the backend `PILAH_ENABLE_DEMO_LOGIN` flag to false; the backend must reject the login even if an older app screen is open. If a production rollout needs to stop, halt it in Play Console and document the decision and recovery owner.
