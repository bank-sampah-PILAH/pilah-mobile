"""Deployment dotenv is public: only validated client settings may ship."""
import os
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
CLIENT = "123-example.apps.googleusercontent.com"
POSTHOG_KEY = "phc_" + "aB3dE5gH7jK9mN1pQ3sT5vW7yZ9bC1dE3fG5hJ7"


class PrepareWebEnvTest(unittest.TestCase):
    def prepare(self, flavor, contents, overrides=None):
        with tempfile.TemporaryDirectory() as directory:
            target = pathlib.Path(directory) / ".env"
            env = {
                name: value
                for name, value in os.environ.items()
                if name not in ("ENABLE_POSTHOG", "POSTHOG_API_KEY", "POSTHOG_HOST", "POSTHOG_ENVIRONMENT")
            }
            env.update({"APP_ENV_FILE": contents, **(overrides or {})})
            result = subprocess.run(["python3", str(ROOT / "scripts/prepare_web_env.py"), flavor, str(target)],
                                    env=env, capture_output=True, text=True, check=False)
            return result, target.read_text() if target.exists() else None

    def test_normalize_api_base_to_origin_and_ship_only_public_settings(self):
        configs = (
            ("staging", "BASE_URL_DEV", "https://pilah-be-staging.fly.dev/api/v1/",
             "https://pilah-be-staging.fly.dev"),
            ("staging", "BASE_URL_DEV", "https://pilah-be-staging.fly.dev",
             "https://pilah-be-staging.fly.dev"),
            ("production", "BASE_URL_PROD", "https://backend-actual.run.app/api/v1/",
             "https://backend-actual.run.app"),
            ("production", "BASE_URL_PROD", "https://backend-actual.run.app",
             "https://backend-actual.run.app"),
        )
        for flavor, key, configured_url, origin in configs:
            with self.subTest(flavor=flavor, configured_url=configured_url):
                result, output = self.prepare(
                    flavor,
                    f"{key} = '{configured_url}'\nGOOGLE_SERVER_CLIENT_ID={CLIENT}\n"
                    "ENABLE_DEMO_LOGIN=true\nSECRET=never-ship\n",
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(
                    output,
                    f"{key}={origin}\nGOOGLE_SERVER_CLIENT_ID={CLIENT}\n"
                    "ENABLE_DEMO_LOGIN=false\n",
                )
                self.assertNotIn(CLIENT, result.stdout + result.stderr)

    def test_reject_missing_invalid_or_ambiguous_configuration_without_writing(self):
        valid = f"BASE_URL_PROD=https://backend.run.app/api/v1/\nGOOGLE_SERVER_CLIENT_ID={CLIENT}\n"
        for contents in ("", valid.replace(CLIENT, ""), valid.replace(CLIENT, "native-client"),
                         valid.replace("https:", "http:"), valid.replace("/api/v1/", "/api/v1"),
                         valid.replace("backend.run.app", "dummyjson.com"),
                         valid.replace("backend.run.app", "user:pass@backend.run.app"),
                         valid + "BASE_URL_PROD=https://other.run.app/api/v1/\n"):
            result, output = self.prepare("production", contents)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Web environment error:", result.stderr)
            self.assertIsNone(output)
            self.assertNotIn(CLIENT, result.stdout + result.stderr)
        result, output = self.prepare("staging", valid.replace("BASE_URL_PROD", "BASE_URL_DEV"))
        self.assertNotEqual(result.returncode, 0)
        self.assertIsNone(output)


    def test_ship_valid_analytics_settings_for_the_matching_flavor(self):
        for flavor, key in (("staging", "BASE_URL_DEV"), ("production", "BASE_URL_PROD")):
            with self.subTest(flavor=flavor):
                origin = ("https://pilah-be-staging.fly.dev" if flavor == "staging"
                          else "https://backend.run.app")
                result, output = self.prepare(
                    flavor,
                    f"{key}={origin}\nGOOGLE_SERVER_CLIENT_ID={CLIENT}\n"
                    f"ENABLE_POSTHOG=true\nPOSTHOG_API_KEY={POSTHOG_KEY}\n"
                    f"POSTHOG_ENVIRONMENT={flavor}\n",
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(
                    output,
                    f"{key}={origin}\nGOOGLE_SERVER_CLIENT_ID={CLIENT}\n"
                    "ENABLE_DEMO_LOGIN=false\nENABLE_POSTHOG=true\n"
                    f"POSTHOG_API_KEY={POSTHOG_KEY}\n"
                    "POSTHOG_HOST=https://us.i.posthog.com\n"
                    f"POSTHOG_ENVIRONMENT={flavor}\n",
                )

    def test_environment_secrets_override_posthog_values_in_app_env_file(self):
        contents = (
            "BASE_URL_PROD=https://backend.run.app\n"
            f"GOOGLE_SERVER_CLIENT_ID={CLIENT}\n"
            "ENABLE_POSTHOG=false\nPOSTHOG_API_KEY=old\nPOSTHOG_ENVIRONMENT=staging\n"
        )
        overrides = {
            "ENABLE_POSTHOG": "true",
            "POSTHOG_API_KEY": POSTHOG_KEY,
            "POSTHOG_HOST": "https://us.i.posthog.com",
            "POSTHOG_ENVIRONMENT": "production",
        }
        result, output = self.prepare("production", contents, overrides)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            output,
            "BASE_URL_PROD=https://backend.run.app\n"
            f"GOOGLE_SERVER_CLIENT_ID={CLIENT}\nENABLE_DEMO_LOGIN=false\n"
            f"ENABLE_POSTHOG=true\nPOSTHOG_API_KEY={POSTHOG_KEY}\n"
            "POSTHOG_HOST=https://us.i.posthog.com\nPOSTHOG_ENVIRONMENT=production\n",
        )

        result, output = self.prepare("production", contents, {"ENABLE_POSTHOG": "true"})
        self.assertNotEqual(result.returncode, 0)
        self.assertIsNone(output)

    def test_reject_invalid_analytics_settings_without_writing(self):
        base = ("BASE_URL_DEV=https://pilah-be-staging.fly.dev\n"
                f"GOOGLE_SERVER_CLIENT_ID={CLIENT}\nENABLE_POSTHOG=true\n")
        valid = base + f"POSTHOG_API_KEY={POSTHOG_KEY}\nPOSTHOG_ENVIRONMENT=staging\n"
        cases = {
            "missing key": base + "POSTHOG_ENVIRONMENT=staging\n",
            "missing environment": base + f"POSTHOG_API_KEY={POSTHOG_KEY}\n",
            "not a project key": valid.replace(POSTHOG_KEY, "not-a-key"),
            "personal api key": valid.replace(POSTHOG_KEY, "phx_" + POSTHOG_KEY[4:]),
            "too short": valid.replace(POSTHOG_KEY, "phc_short"),
            "eu host": valid + "POSTHOG_HOST=https://eu.i.posthog.com\n",
            "plain http host": valid + "POSTHOG_HOST=http://us.i.posthog.com\n",
            "unknown host": valid + "POSTHOG_HOST=https://analytics.example.com\n",
            "production environment on staging": valid.replace("=staging", "=production"),
            "duplicate key": valid + f"POSTHOG_API_KEY={POSTHOG_KEY}\n",
        }
        for name, contents in cases.items():
            with self.subTest(name):
                result, output = self.prepare("staging", contents)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("Web environment error:", result.stderr)
                self.assertIsNone(output)
                self.assertNotIn(POSTHOG_KEY, result.stdout + result.stderr)

    def test_ship_nothing_for_analytics_that_is_not_enabled(self):
        for flag in ("ENABLE_POSTHOG=false\n", ""):
            with self.subTest(flag=flag):
                result, output = self.prepare(
                    "staging",
                    "BASE_URL_DEV=https://pilah-be-staging.fly.dev\n"
                    f"GOOGLE_SERVER_CLIENT_ID={CLIENT}\n{flag}"
                    f"POSTHOG_API_KEY={POSTHOG_KEY}\nPOSTHOG_ENVIRONMENT=staging\n",
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIsNotNone(output)
                assert output is not None
                self.assertNotIn("POSTHOG", output)
                self.assertNotIn("ENABLE_POSTHOG", output)


if __name__ == "__main__":
    unittest.main()
