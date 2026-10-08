"""Check deployment boundaries in the workflows actionlint also validates."""
import os
import pathlib
import subprocess
import unittest

import yaml

ROOT = pathlib.Path(__file__).resolve().parents[2]


def workflow(name):
    return yaml.load((ROOT / ".github/workflows" / name).read_text(), Loader=yaml.BaseLoader)


class WebPipelineTest(unittest.TestCase):
    def test_staging_is_automatic_only_after_merge_gate(self):
        ci = workflow("ci.yml")
        self.assertIn("staging", ci["on"]["push"]["branches"])
        job = ci["jobs"]["deploy_web_staging"]
        self.assertEqual(job["needs"], "verify")
        self.assertEqual(job["if"], "github.event_name == 'push' && github.ref == 'refs/heads/staging'")
        self.assertEqual(job["with"]["flavor"], "staging")
        self.assertEqual(job["uses"], "./.github/workflows/deploy-web.yml")

    def test_production_follows_tags_and_web_jobs_do_not_need_android_secrets(self):
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
        self.assertIn("/healthz", text)

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

    def test_bootstrap_does_not_register_obsolete_service_worker(self):
        bootstrap = (ROOT / "web/flutter_bootstrap.js").read_text()
        self.assertIn("{{flutter_js}}", bootstrap)
        self.assertIn("{{flutter_build_config}}", bootstrap)
        self.assertIn("_flutter.loader.load();", bootstrap)
        self.assertNotIn("serviceWorkerSettings", bootstrap)


if __name__ == "__main__":
    unittest.main()
