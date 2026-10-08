# Dashboard hosting (PIL-335)

Separate static dashboard apps; no custom domain or DNS. Supported web roles:
**Super Admin, Pengurus, Pengurus Induk** (not Nasabah). Native APK release
workflows remain independent and unchanged.

| Environment | Dashboard | API / entrypoint |
| --- | --- | --- |
| staging | `https://pilah-web-staging.fly.dev` (Fly, `sin`) | `https://pilah-be-staging.fly.dev`, `lib/main_development.dart` |
| production | Actual `status.url` returned by Cloud Run service `pilah-web` | production `APP_ENV_FILE`'s `BASE_URL_PROD` backend origin, `lib/main_production.dart` |

`BASE_URL_DEV` and `BASE_URL_PROD` are backend origins, without an API path.
Mobile request paths already include `/api/v1`; the build script also strips a
legacy `/api/v1/` suffix from these values before writing the public dotenv.

The production `*.run.app` hostname is provider-generated. Do not guess it.
The deploy job checks HTTPS `/healthz` and `/`, then prints the verified URL
in its Actions summary. This proves static availability, **not** OAuth or
an authenticated dashboard session.

## Setup required before enabling delivery

These are maintainer provisioning steps, not actions performed by this PR.

1. Create GitHub environments `staging` and `production`. Restrict staging to
   the `staging` branch and production to version tags. **Require production
   reviewers**; naming an environment alone does not enable approval protection.
2. Set environment secret `APP_ENV_FILE` using the existing application format:
   ```dotenv
   BASE_URL_DEV=https://pilah-be-staging.fly.dev
   BASE_URL_PROD=https://ACTUAL-PRODUCTION-BACKEND.run.app
   GOOGLE_SERVER_CLIENT_ID=NUMERIC-ID-WEB-CLIENT.apps.googleusercontent.com
   ENABLE_DEMO_LOGIN=false
   ```
   Replace examples with real values. Only the selected API key, Google Web
   client ID and `ENABLE_DEMO_LOGIN=false` enter the public `.env` web asset.
   Missing/duplicate keys, a non-HTTPS API, wrong staging API, an unexpected
   API path, and malformed client IDs fail before build. Do not put server
   secrets in browser settings. The script never sources shell dotenv values.
3. Provision **separate** Fly app `pilah-web-staging` in the intended organization
   and allocate its provider hostname/networking as required by Fly. Put an
   app-scoped deploy token in staging secret `FLY_API_TOKEN` (not a backend
   app token). `deploy/web/fly.staging.toml` forces HTTPS, uses port 8080 and
   checks `/healthz`. No Fly secrets are needed by this static runtime.
4. In production, enable Cloud Run, Artifact Registry and IAM/WIF APIs, create a
   Docker Artifact Registry repository, and set these GitHub environment vars
   (same naming as backend where shared):
   - `GCP_PROJECT_ID`, `GCP_REGION` (e.g. `asia-southeast2`), `ARTIFACT_REPO`.
   - `GCP_WORKLOAD_IDENTITY_PROVIDER`: full `projects/NUMBER/locations/global/`
     `workloadIdentityPools/POOL/providers/PROVIDER` resource name.
   - `GCP_SERVICE_ACCOUNT`: deployment service-account email. WIF must trust
     only this GitHub repository and approved production context. Grant its
     federated principal Workload Identity User; grant the deployment account
     Artifact Registry Writer, Cloud Run Admin (including public invoker policy)
     and Service Account User on the runtime account.
   - `RUNTIME_WEB_SERVICE_ACCOUNT`: a dedicated minimally privileged static
     web runtime account; no backend DB, storage or OAuth-secret permissions.
   - Optional `CLOUD_RUN_WEB_SERVICE`, defaults to **`pilah-web`**. Do not use
     backend `CLOUD_RUN_SERVICE`. Image name equals web service name; image URI
     is `REGION-docker.pkg.dev/PROJECT/ARTIFACT_REPO/SERVICE:COMMIT_SHA`.
   The workflow uses WIF, not a downloaded service-account key. Cloud Run is
   publicly invokable and receives port 8080 plus an HTTP startup probe.

## Origin and Google client contract

`GOOGLE_SERVER_CLIENT_ID` must equal backend `GOOGLE_CLIENT_ID`: the **Web OAuth
client ID**, not Android/iOS client IDs. Confirm equality privately; do not
paste credentials in CI logs or PRs.

- Backend Fly staging must allow exactly `https://pilah-web-staging.fly.dev`
  for CORS/CSRF. No trailing slash, wildcard, path or hash fragment in origins.
- After the first approved production deployment yields `status.url`, set the
  **backend repository's production variable `PILAH_WEB_ORIGIN`** to that exact
  HTTPS origin and redeploy the backend. The backend companion `feature/pil-335`
  supplies the exact-origin CORS/CSRF contract. Do not substitute the API URL
  for the web origin or enable wildcard CORS to work around failures.
- In Google Cloud Console, add **both actual dashboard provider origins** to
  that Web client's **Authorized JavaScript origins**. Local QA needs its own
  authorized localhost origin if testing real login. Google OAuth redirect /
  callback configuration remains the backend's existing callback; this static
  dashboard does not add a callback endpoint.

Until backend origin settings and Google Console configuration are completed,
static access can succeed while Google login/API requests fail. Cloud/OAuth
changes require separate authorization; this delivery does not perform them.

## Pipeline and serving behavior

- `CI` now verifies `staging` pushes as well as PRs/existing `main` pushes.
  `deploy_web_staging` runs automatically **only after successful CI verify on
  a staging push**, using the exact triggering checkout; PRs never deploy.
- Existing `v*` production release tags also call a separate web job, gated by
  the `production` environment. Tags run their own analyze/tests before the
  production web build. Web jobs do not depend on the APK job, Android signing
  secrets or Firebase config. Existing APK delivery remains as before.
- Flutter is pinned to 3.41.3. Each job installs the locked dependencies,
  generates code, writes sanitized public settings, builds release web once,
  uploads a 14-day Actions artifact, then serves the same `build/web` through
  `deploy/web/Dockerfile`. Fly uses its remote image builder; production pushes
  the static image to Artifact Registry. Artifact includes the public `.env`.
  Root `.dockerignore` uploads only `build/web` and the Nginx configuration,
  excluding the private source `.env`, Firebase config and native build output.
- Nginx listens on 8080. All index/bootstrap/JS/assets use `Cache-Control:
  no-cache` with ETags (revalidate, not immutable). Flutter's standard names
  are **not content fingerprints**. No blanket JS immutable cache rule is safe.
- Hash routing (`/#/...`) needs no server rewrite: `/missing.js` and a literal
  `/dashboard` return 404, not HTML with status 200. `/healthz` returns `ok`.
- `web/flutter_bootstrap.js` uses the supported bootstrap template without
  service-worker settings. No deprecated `--pwa-strategy` option is used; no
  offline worker is registered. These new provider apps have no prior worker.
  If migrating from an older install/origin, unregister its old worker and
  clear its caches once; disabling registration cannot clear an already
  controlling old worker. Dashboard requires an online API.

## Local checks and post-deploy verification

With the authorized Flutter SDK and local Android config from `AGENTS.md`:

```sh
flutter pub get --enforce-lockfile
dart run build_runner build --delete-conflicting-outputs
flutter analyze --fatal-infos
flutter test
flutter build apk --debug -t lib/main_development.dart
flutter build web --release -t lib/main_development.dart
flutter build web --release -t lib/main_production.dart
python3 -m pip install PyYAML==6.0.3
python3 -m unittest discover -s scripts/tests -v
docker run --rm -v "$PWD":/repo -w /repo rhysd/actionlint:latest -color
```

Hosting tests build a temporary fixture using the actual Nginx Dockerfile and
assert cache revalidation (304), health, missing-resource 404 and no SPA fallback.
Environment tests exercise missing/invalid config, demo disabling and secret
exclusion; a real Docker context check excludes private/native files. Pipeline
checks enforce deploy boundaries and config fail-fast. The bootstrap regression
resolves authentication using both real development and production DI graphs:
its test-only platform override is excluded from injectable code generation.

For local web QA, serve a release bundle with
`python3 -m http.server 7357 --bind 127.0.0.1 --directory build/web`, inspect
1440×900 and 390×844 viewports, console/network and hash navigation. Browser
mobile emulation is not native-app smoke verification. Hosting-only changes
need no UI screenshots. Only use authorized accounts for real role verification.

After an approved live deploy:

1. Open the job's reported HTTPS URL, then reload a `/#/...` route. Check
   `curl -I URL/main.dart.js` and `URL/flutter_bootstrap.js` for `no-cache`,
   `curl URL/healthz` for `ok`, and `URL/missing.js` for 404.
2. Ensure the selected API points at the corresponding backend (including the
   trailing slash), production has no demo entry, and no worker is registered.
3. Complete exact backend/Google origins above, then verify real Google login
   and authorized API access for each supported web role. Inspect CORS/preflight
   and console errors; do not interpret a login-page load as authenticated QA.
4. For rollback, use the provider's known-good Fly release / Cloud Run revision
   following maintainer procedures; do not retag or force-push release history.

Live Fly/GCP provisioning, production URL discovery, OAuth console settings,
and authenticated role smoke tests remain required operational follow-up.
