"""Guard the Nuclei exposure scan: target parsing, gate granularity and deploy wiring."""
import json
import os
import pathlib
import shutil
import subprocess
import tempfile
import unittest

import yaml

ROOT = pathlib.Path(__file__).resolve().parents[2]


def workflow(name):
    return yaml.load((ROOT / ".github/workflows" / name).read_text(), Loader=yaml.BaseLoader)


def steps():
    scan = workflow("nuclei-scan.yml")["jobs"]["nuclei-scan"]["steps"]
    return {step["name"]: step for step in scan if "name" in step}


def run_step(name, env, workdir):
    return subprocess.run(
        ["bash", "-eo", "pipefail", "-c", steps()[name]["run"]],
        cwd=workdir,
        env={**os.environ, **env},
        capture_output=True,
        text=True,
        check=False,
    )


OWN_REPOSITORY = "bank-sampah-PILAH/pilah-mobile"


class NucleiScanTargetTest(unittest.TestCase):
    def resolve(self, url, target_url="", environment="staging", repository=OWN_REPOSITORY):
        with tempfile.TemporaryDirectory() as directory:
            github_env = pathlib.Path(directory) / "github_env"
            github_env.write_text("")
            result = run_step(
                "Resolve target",
                {
                    "ENVIRONMENT": environment,
                    "TARGET_URL_INPUT": target_url,
                    "STAGING_WEB_URL": url,
                    "PRODUCTION_WEB_URL": "",
                    "GITHUB_ENV": str(github_env),
                    "GITHUB_REPOSITORY": repository,
                },
                directory,
            )
            # Splitting on the first "=" of each line mirrors how GitHub reads the file, so
            # an injected line shows up here as an extra key.
            return result, dict(
                line.split("=", 1) for line in github_env.read_text().splitlines()
            )

    def test_targets_are_reduced_to_host_and_port(self):
        # A trailing slash and an explicit :443 must not leak into the TLS target
        # (host:443:443).
        for url in (
            "https://web.example",
            "https://web.example/",
            "https://web.example:443",
        ):
            with self.subTest(url=url):
                result, resolved = self.resolve(url)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(resolved["TARGET"], "https://web.example")
                self.assertEqual(resolved["TLS_TARGET"], "web.example:443")
                self.assertEqual(resolved["RESULT_NAME"], "web.example-443")
        _, custom = self.resolve("https://web.example:8443/")
        self.assertEqual(custom["TARGET"], "https://web.example:8443")
        self.assertEqual(custom["TLS_TARGET"], "web.example:8443")

    def test_target_from_the_caller_overrides_the_variable(self):
        _, resolved = self.resolve(
            "", target_url="https://deployed.run.app", environment="production"
        )
        self.assertEqual(resolved["TARGET"], "https://deployed.run.app")

    def test_unusable_targets_are_rejected(self):
        for url in (
            "",
            "http://web.example",
            "https://web.example:99999",
            "https://web.example:abc",
            "https://user:pass@web.example",
            "https://[::1]",
        ):
            with self.subTest(url=url):
                result, resolved = self.resolve(url)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("::error::", result.stdout + result.stderr)
                self.assertEqual(resolved, {})

    def test_urls_that_would_change_the_scan_scope_are_rejected(self):
        # STAGING_WEB_URL=https://host/app used to scan https://host without a word.
        for url in (
            "https://web.example/app",
            "https://web.example/path?q=1",
            "https://web.example?q=1",
            "https://web.example#frag",
        ):
            with self.subTest(url=url):
                result, resolved = self.resolve(url)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("::error::", result.stdout + result.stderr)
                self.assertEqual(resolved, {})

    def test_a_target_cannot_smuggle_environment_variables(self):
        # The target is appended to $GITHUB_ENV one KEY=value per line, so a newline in a
        # caller-supplied target_url would define any variable for the later steps.
        for url in (
            "https://ok.example\nEVIL=injected",
            "https://ok.example\r\nEVIL=injected",
            "https://ok.example EVIL=injected",
        ):
            with self.subTest(url=repr(url)):
                result, resolved = self.resolve("", target_url=url)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("::error::", result.stdout + result.stderr)
                self.assertEqual(resolved, {})
                self.assertNotIn("EVIL=injected", result.stdout + result.stderr)

    def test_only_this_repository_can_use_the_scan(self):
        # The workflow is reusable from a public repository, and both target_url and the
        # variables resolve in the caller's repository.
        for kwargs in (
            {"url": "", "target_url": "https://deployed.run.app"},
            {"url": "https://web.example"},
        ):
            with self.subTest(**kwargs):
                result, resolved = self.resolve(repository="someone/else", **kwargs)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("::error::", result.stdout + result.stderr)
                self.assertEqual(resolved, {})


@unittest.skipUnless(shutil.which("jq"), "jq is not installed")
class NucleiScanGateTest(unittest.TestCase):
    @staticmethod
    def finding(template, matcher=None, matched="https://web.example"):
        item = {
            "template-id": template,
            "host": "web.example",
            "info": {"severity": "info"},
            "matched-at": matched,
        }
        if matcher:
            item["matcher-name"] = matcher
        return item

    def gate(self, findings):
        with tempfile.TemporaryDirectory() as directory:
            results = pathlib.Path(directory) / "results"
            results.mkdir()
            (results / "scan.jsonl").write_text(
                "".join(json.dumps(item) + "\n" for item in findings)
            )
            return run_step("Gate", {}, directory)

    def test_accepted_headers_pass_but_an_unlisted_header_fails(self):
        accepted = [
            self.finding("http-missing-security-headers", "strict-transport-security"),
            self.finding("http-missing-security-headers", "permissions-policy"),
            self.finding("weak-csp-detect", "missing-script-src"),
        ]
        self.assertEqual(self.gate(accepted).returncode, 0)
        # Accepting HSTS must not hide a missing CSP header.
        csp = self.gate(
            [*accepted, self.finding("http-missing-security-headers", "content-security-policy")]
        )
        self.assertNotEqual(csp.returncode, 0)
        self.assertIn("content-security-policy", csp.stdout + csp.stderr)

    def test_a_leaked_build_file_fails_and_no_results_fail(self):
        leaked = self.finding("pubspec-config", matched="https://web.example/pubspec.yaml")
        self.assertNotEqual(self.gate([leaked]).returncode, 0)
        with tempfile.TemporaryDirectory() as directory:
            self.assertNotEqual(run_step("Gate", {}, directory).returncode, 0)


class NucleiScanWiringTest(unittest.TestCase):
    def test_staging_scan_follows_the_staging_web_deploy(self):
        job = workflow("ci.yml")["jobs"]["nuclei_post_deploy"]
        self.assertEqual(job["needs"], "deploy_web_staging")
        self.assertIn("refs/heads/staging", job["if"])
        # The scan targets the URL the staging deploy just used, not a repository variable
        # that can drift or be mistyped while /health still answers 200 somewhere else.
        self.assertEqual(
            job["with"],
            {
                "environment": "staging",
                "target_url": "${{ needs.deploy_web_staging.outputs.url }}",
            },
        )
        self.assertNotIn("continue-on-error", job)

    def test_staging_deploy_reports_the_url_it_deployed(self):
        deploy = workflow("deploy-web.yml")
        self.assertEqual(
            deploy["jobs"]["deploy"]["outputs"]["url"],
            "${{ steps.deploy_staging.outputs.url || steps.deploy_production.outputs.url }}",
        )
        reporter = next(
            step
            for step in deploy["jobs"]["deploy"]["steps"]
            if step.get("id") == "deploy_staging"
        )
        self.assertEqual(reporter["if"], "inputs.flavor == 'staging'")
        self.assertIn("url=https://pilah-web-staging.fly.dev", reporter["run"])
        self.assertIn('echo "url=$url" >> "$GITHUB_OUTPUT"', reporter["run"])

    def test_production_scan_scans_the_url_the_deploy_reported(self):
        deploy = workflow("deploy-web.yml")
        self.assertEqual(
            deploy["on"]["workflow_call"]["outputs"]["url"]["value"],
            "${{ jobs.deploy.outputs.url }}",
        )
        production = deploy["jobs"]["deploy"]["steps"]
        reporter = next(step for step in production if step.get("id") == "deploy_production")
        self.assertIn('echo "url=$url" >> "$GITHUB_OUTPUT"', reporter["run"])
        job = workflow("cd-production.yml")["jobs"]["nuclei_post_deploy"]
        self.assertEqual(job["needs"], "deploy_web_production")
        self.assertEqual(job["if"], "github.event_name == 'push'")
        self.assertEqual(job["with"]["environment"], "production")
        self.assertEqual(
            job["with"]["target_url"], "${{ needs.deploy_web_production.outputs.url }}"
        )
        self.assertNotIn("continue-on-error", job)


if __name__ == "__main__":
    unittest.main()
