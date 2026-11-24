"""Check deployment boundaries in the workflows actionlint also validates."""
import os
import pathlib
import subprocess
import tomllib
import unittest

import yaml

ROOT = pathlib.Path(__file__).resolve().parents[2]


def workflow(name):
    return yaml.load((ROOT / ".github/workflows" / name).read_text(), Loader=yaml.BaseLoader)


class WebPipelineTest(unittest.TestCase):
    def test_staging_fly_dockerfile_resolves_from_config_directory(self):
        config = ROOT / "deploy/web/fly.staging.toml"
        dockerfile = tomllib.loads(config.read_text())["build"]["dockerfile"]
        self.assertTrue((config.parent / dockerfile).is_file())

    def test_staging_is_automatic_only_after_merge_gate(self):
        ci = workflow("ci.yml")
        self.assertIn("staging", ci["on"]["push"]["branches"])
        self.assertEqual(
            ci["concurrency"]["cancel-in-progress"],
            "${{ github.ref != 'refs/heads/staging' }}",
        )
        job = ci["jobs"]["deploy_web_staging"]
        self.assertEqual(job["needs"], "verify")
        self.assertEqual(
            job["if"],
            "${{ !cancelled() && needs.verify.result == 'success' && github.event_name == 'push' && github.ref == 'refs/heads/staging' }}",
        )
        self.assertEqual(job["with"]["flavor"], "staging")
        self.assertEqual(job["uses"], "./.github/workflows/deploy-web.yml")

    def test_production_follows_tags_and_web_jobs_do_not_need_android_secrets(self):
        ci = workflow("ci.yml")
        self.assertNotIn("deploy_web_production", ci["jobs"])
        release = workflow("cd-production.yml")
        self.assertEqual(release["on"]["push"]["tags"], ["v*"])
        job = release["jobs"]["deploy_web_production"]
        self.assertNotIn("needs", job)  # Independent of native signing/Firebase.
        self.assertEqual(job["with"]["flavor"], "production")
        deploy = workflow("deploy-web.yml")
        self.assertEqual(list(deploy["on"]), ["workflow_call"])
        self.assertEqual(deploy["jobs"]["deploy"]["environment"], "${{ inputs.flavor }}")
        text = (ROOT / ".github/workflows/deploy-web.yml").read_text()
        for secret in ("ANDROID_KEY", "GOOGLE_SERVICES_JSON"):
            self.assertNotIn(secret, text)
        self.assertIn("python3 scripts/prepare_web_env.py", text)
        self.assertIn("flutter build web --release", text)
        self.assertNotIn("--pwa-strategy", text)
        self.assertIn("status.url", text)
        self.assertIn("/health", text)

    def test_source_maps_are_uploaded_and_never_deployed(self):
        steps = workflow("deploy-web.yml")["jobs"]["deploy"]["steps"]
        names = [step.get("name", "") for step in steps]
        build = names.index("Build dashboard once")
        upload = names.index("Upload source maps to PostHog")
        guard = names.index("Keep source maps out of the deployed files")
        artifact = names.index("Upload web artifact")
        # Maps are built, uploaded, removed, and only then does anything leave
        # the runner (the artifact, the Fly deploy, the production image).
        self.assertLess(build, upload)
        self.assertLess(upload, guard)
        self.assertLess(guard, artifact)
        self.assertIn("--source-maps", steps[build]["run"])
        # A failed upload costs readable stack traces, not the deploy, and the
        # removal runs whatever the upload did.
        self.assertEqual(steps[upload]["continue-on-error"], "true")
        self.assertEqual(steps[guard]["if"], "${{ always() }}")
        self.assertIn("-name '*.map' -delete", steps[guard]["run"])
        # The release is the version the app reports, so frames match events.
        self.assertIn("APP_VERSION", steps[build]["run"])
        self.assertIn("$APP_VERSION", steps[upload]["run"])
        # The project id is a constant, not a secret; only the key is secret.
        self.assertEqual(steps[upload]["env"]["POSTHOG_CLI_PROJECT_ID"], "693641")
        self.assertIn("secrets.POSTHOG_CLI_API_KEY", steps[upload]["env"]["POSTHOG_CLI_API_KEY"])

    def test_android_builds_keep_symbols_and_upload_them_without_blocking(self):
        for name in ("cd-staging.yml", "cd-production.yml"):
            jobs = workflow(name)["jobs"]
            steps = next(
                job["steps"]
                for job in jobs.values()
                if any("--split-debug-info=build/symbols" in step.get("run", "") for step in job.get("steps", []))
            )
            names = [step.get("name", "") for step in steps]
            upload = steps[names.index("Upload debug symbols to PostHog")]
            self.assertEqual(upload["continue-on-error"], "true", name)
            self.assertIn("symbol-sets upload --directory build/symbols", upload["run"], name)
            self.assertEqual(upload["env"]["POSTHOG_CLI_PROJECT_ID"], "693641", name)

    def test_invalid_hosting_configuration_fails_before_cloud_auth(self):
        steps = workflow("deploy-web.yml")["jobs"]["deploy"]["steps"]
        script = next(step["run"] for step in steps if step.get("name") == "Validate hosting configuration")
        valid = {"FLAVOR": "production", "PROJECT_ID": "pilah-prod-123", "REGION": "asia-southeast2",
                 "SERVICE_NAME": "pilah-web", "ARTIFACT_REPO": "pilah",
                 "WORKLOAD_PROVIDER": "projects/123/locations/global/workloadIdentityPools/github/providers/github",
                 "DEPLOY_SERVICE_ACCOUNT": "deploy@pilah-prod-123.iam.gserviceaccount.com",
                 "RUNTIME_SERVICE_ACCOUNT": "web@pilah-prod-123.iam.gserviceaccount.com"}

        def run(config):
            return subprocess.run(["bash", "-e", "-o", "pipefail", "-c", script],
                                  env={"PATH": os.environ["PATH"], **config}, capture_output=True).returncode

        self.assertEqual(run(valid), 0)
        for name in valid:
            with self.subTest(missing=name):
                self.assertNotEqual(run({**valid, name: ""}), 0)
        for name in valid:
            with self.subTest(invalid=name):
                self.assertNotEqual(run({**valid, name: "bad value; echo unsafe"}), 0)
        self.assertNotEqual(run({"FLAVOR": "staging"}), 0)
        self.assertEqual(run({"FLAVOR": "staging", "FLY_API_TOKEN": "test-only"}), 0)

    def test_browser_favicon_kit_is_linked_and_branded(self):
        index = (ROOT / "web/index.html").read_text()
        manifest = (ROOT / "web/site.webmanifest").read_text()
        for asset in (
            "favicon.ico", "icons/favicon-16x16.png", "icons/favicon-32x32.png",
            "apple-touch-icon.png", "site.webmanifest",
        ):
            with self.subTest(asset=asset):
                self.assertIn(asset, index)
                self.assertTrue((ROOT / "web" / asset).is_file())
        for asset in ("android-chrome-192x192.png", "android-chrome-512x512.png"):
            with self.subTest(asset=asset):
                self.assertIn(asset, manifest)
                self.assertTrue((ROOT / "web" / asset).is_file())
        self.assertIn('<title>PILAH | Beranda</title>', index)
        self.assertIn('"name": "PILAH"', manifest)
        self.assertIn('"short_name": "PILAH"', manifest)

    def test_bootstrap_does_not_register_obsolete_service_worker(self):
        bootstrap = (ROOT / "web/flutter_bootstrap.js").read_text()
        self.assertIn("{{flutter_js}}", bootstrap)
        self.assertIn("{{flutter_build_config}}", bootstrap)
        self.assertIn("_flutter.loader.load();", bootstrap)
        self.assertNotIn("serviceWorkerSettings", bootstrap)


if __name__ == "__main__":
    unittest.main()
