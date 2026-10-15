"""Keep Play releases gated, signed, and tied to one immutable AAB."""
import pathlib
import unittest

import yaml

ROOT = pathlib.Path(__file__).resolve().parents[2]


def workflow():
    return yaml.load(
        (ROOT / ".github/workflows/cd-production.yml").read_text(),
        Loader=yaml.BaseLoader,
    )


class PlayReleasePipelineTest(unittest.TestCase):
    def test_tag_release_gates_aab_upload_on_quality_checks(self):
        release = workflow()
        self.assertEqual(release["on"]["push"]["tags"], ["v*"])
        self.assertIn("workflow_dispatch", release["on"])

        verify = release["jobs"]["verify"]
        verify_text = "\n".join(step.get("run", "") for step in verify["steps"])
        self.assertIn("flutter analyze --fatal-infos", verify_text)
        self.assertIn("flutter test --coverage", verify_text)
        self.assertIn("sonar.qualitygate.wait=true", str(verify))

        build = release["jobs"]["release"]
        self.assertEqual(build["needs"], "verify")
        self.assertEqual(build["environment"], "production")
        steps = build["steps"]
        text = "\n".join(step.get("run", "") for step in steps)
        self.assertIn("scripts/prepare_web_env.py production .env", text)
        self.assertIn("PLAY_TEST_SERVICE_ACCOUNT_JSON", text)
        self.assertIn("flutter build appbundle --release -t lib/main_production.dart", text)
        self.assertIn("sha256sum", text)

        upload = next(
            step for step in steps
            if step.get("uses", "").startswith("r0adkll/upload-google-play@")
            and step["with"].get("tracks") == "alpha"
        )
        self.assertEqual(upload["with"]["packageName"], "com.mobile.pilahapp")
        self.assertEqual(upload["with"]["tracks"], "alpha")
        self.assertEqual(
            upload["with"]["releaseFiles"],
            "build/app/outputs/bundle/release/app-release.aab",
        )
        gradle = (ROOT / "android/app/build.gradle").read_text()
        self.assertIn('applicationId = "com.mobile.pilahapp"', gradle)

    def test_production_promotion_downloads_and_verifies_the_tested_aab(self):
        promote = workflow()["jobs"]["promote_production"]
        self.assertEqual(promote["if"], "github.event_name == 'workflow_dispatch'")
        steps = promote["steps"]
        text = "\n".join(step.get("run", "") for step in steps)
        self.assertIn("gh release download", text)
        self.assertIn("sha256sum --check", text)
        self.assertNotIn("flutter build", text)

        upload = next(
            step for step in steps
            if step.get("uses", "").startswith("r0adkll/upload-google-play@")
            and step["with"].get("tracks") == "production"
        )
        self.assertEqual(upload["with"]["packageName"], "com.mobile.pilahapp")
        self.assertEqual(upload["with"]["tracks"], "production")
        self.assertEqual(upload["with"]["releaseFiles"], "dist/app-release.aab")
        self.assertIn("PLAY_PRODUCTION_SERVICE_ACCOUNT_JSON", upload["with"]["serviceAccountJsonPlainText"])

    def test_play_version_is_newer_than_rejected_version_code(self):
        pubspec = (ROOT / "pubspec.yaml").read_text()
        self.assertIn("version: 1.0.1+7", pubspec)


if __name__ == "__main__":
    unittest.main()
