"""Deployment dotenv is public: only validated client settings may ship."""
import os
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
CLIENT = "123-example.apps.googleusercontent.com"


class PrepareWebEnvTest(unittest.TestCase):
    def prepare(self, flavor, contents):
        with tempfile.TemporaryDirectory() as directory:
            target = pathlib.Path(directory) / ".env"
            result = subprocess.run(["python3", str(ROOT / "scripts/prepare_web_env.py"), flavor, str(target)],
                                    env={**os.environ, "APP_ENV_FILE": contents}, capture_output=True, text=True)
            return result, target.read_text() if target.exists() else None

    def test_ship_only_selected_public_settings_and_disable_demo(self):
        for flavor, key, api in (("staging", "BASE_URL_DEV", "https://pilah-be-staging.fly.dev/api/v1/"),
                                 ("production", "BASE_URL_PROD", "https://backend-actual.run.app/api/v1/")):
            result, output = self.prepare(flavor, f"{key} = '{api}'\nGOOGLE_SERVER_CLIENT_ID={CLIENT}\nENABLE_DEMO_LOGIN=true\nSECRET=never-ship\n")
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(output, f"{key}={api}\nGOOGLE_SERVER_CLIENT_ID={CLIENT}\nENABLE_DEMO_LOGIN=false\n")
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


if __name__ == "__main__":
    unittest.main()
