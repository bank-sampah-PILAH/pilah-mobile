"""Keep PostHog build settings deployment-specific and dotenv-safe."""

import os
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts/append_posthog_env.py"


class AppendPosthogEnvTest(unittest.TestCase):
    def run_append(self, flavor, contents, overrides=None):
        with tempfile.TemporaryDirectory() as directory:
            target = pathlib.Path(directory) / ".env"
            target.write_text(contents)
            env = {
                **os.environ,
                "ENABLE_POSTHOG": "true",
                "POSTHOG_API_KEY": "phc_abcdefghijklmnopqrstuvwxyz1234",
                "POSTHOG_HOST": "https://us.i.posthog.com",
                "POSTHOG_ENVIRONMENT": flavor,
                **(overrides or {}),
            }
            result = subprocess.run(
                ["python3", str(SCRIPT), flavor, str(target)],
                env=env,
                capture_output=True,
                text=True,
                check=False,
            )
            return result, target.read_text()

    def test_writes_selected_environment_and_replaces_old_posthog_values(self):
        for flavor in ("staging", "production"):
            with self.subTest(flavor=flavor):
                result, output = self.run_append(
                    flavor,
                    "BASE_URL=https://example.com\nPOSTHOG_ENVIRONMENT=old\nPOSTHOG_API_KEY=old\n",
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(
                    output,
                    "BASE_URL=https://example.com\n"
                    "ENABLE_POSTHOG=true\n"
                    "POSTHOG_API_KEY=phc_abcdefghijklmnopqrstuvwxyz1234\n"
                    "POSTHOG_HOST=https://us.i.posthog.com\n"
                    f"POSTHOG_ENVIRONMENT={flavor}\n",
                )

    def test_rejects_invalid_or_mismatched_settings_without_modifying_dotenv(self):
        existing = "BASE_URL=https://example.com\n"
        invalid = (
            {"ENABLE_POSTHOG": "false"},
            {"POSTHOG_API_KEY": ""},
            {"POSTHOG_API_KEY": "phc_short"},
            {"POSTHOG_API_KEY": "key\nPOSTHOG_ENVIRONMENT=production"},
            {"POSTHOG_HOST": "http://us.i.posthog.com"},
            {"POSTHOG_HOST": "https://user@us.i.posthog.com"},
            {"POSTHOG_HOST": "https://us.i.posthog.com:invalid"},
            {"POSTHOG_HOST": "https://us.i.posthog.com/path"},
            {"POSTHOG_HOST": "https://us.i.posthog.com\nINJECTED=true"},
            {"POSTHOG_ENVIRONMENT": "production"},
        )
        for override in invalid:
            with self.subTest(override=override):
                result, output = self.run_append("staging", existing, override)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(output, existing)
                self.assertNotIn("phc_abcdefghijklmnopqrstuvwxyz1234", result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
