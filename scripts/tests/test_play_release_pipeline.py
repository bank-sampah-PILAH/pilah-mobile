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
        self.assertNotIn("environment", verify)
        steps = verify["steps"]
        step_names = [step.get("name", "") for step in steps]
        dependency_index = step_names.index("Install release workflow test dependencies")
        safeguard_index = step_names.index("Check release workflow safeguards")
        self.assertLess(dependency_index, safeguard_index)
        self.assertIn("PyYAML==6.0.3", steps[dependency_index]["run"])

        verify_text = "\n".join(step.get("run", "") for step in verify["steps"])
        self.assertIn("flutter analyze --fatal-infos", verify_text)
        self.assertIn("flutter test --coverage", verify_text)
        self.assertIn("sonar.qualitygate.wait=true", str(verify))
        self.assertIn("${{ secrets.SONAR_TOKEN }}", str(verify))

        sonar_scan = next(step for step in steps if step.get("id") == "sonar_scan")
        sonar_retry = next(step for step in steps if step.get("id") == "sonar_retry")
        self.assertEqual(sonar_scan["continue-on-error"], "true")
        self.assertEqual(sonar_retry["if"], "steps.sonar_scan.outcome == 'failure'")
        self.assertEqual(sonar_retry["continue-on-error"], "true")
        self.assertEqual(sonar_retry["with"]["args"], sonar_scan["with"]["args"])
        self.assertIn("-Dsonar.qualitygate.wait=true", sonar_scan["with"]["args"])
        self.assertIn("-Dsonar.qualitygate.wait=true", sonar_retry["with"]["args"])
        final_gate = next(step for step in steps if step.get("name") == "Enforce SonarCloud quality gate")
        self.assertEqual(final_gate["if"], "always()")
        self.assertIn("SONAR_RETRY_OUTCOME", final_gate["env"])
        self.assertIn("exit 1", final_gate["run"])

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
        self.assertIn("--pattern release-metadata.txt", text)
        self.assertNotIn("flutter build", text)
        self.assertIn("scripts/promote_play_release.py", text)
        self.assertNotIn("r0adkll/upload-google-play@", str(steps))
        self.assertIn("google-auth==2.62.0", str(steps))
        self.assertIn("PLAY_PRODUCTION_SERVICE_ACCOUNT_JSON", str(steps))
        self.assertIn("PLAY_TEST_SERVICE_ACCOUNT_JSON", str(steps))

    def test_track_promotion_never_falls_back_to_test_credentials_for_production(self):
        steps = workflow()["jobs"]["promote_production"]["steps"]
        test_promotion = next(
            step for step in steps if step.get("name") == "Promote existing bundle to test track"
        )
        production_promotion = next(
            step for step in steps if step.get("name") == "Promote existing bundle to production"
        )

        self.assertEqual(test_promotion["if"], "inputs.track != 'production'")
        self.assertEqual(
            test_promotion["env"]["PLAY_SERVICE_ACCOUNT_JSON"],
            "${{ secrets.PLAY_TEST_SERVICE_ACCOUNT_JSON }}",
        )
        self.assertEqual(production_promotion["if"], "inputs.track == 'production'")
        self.assertEqual(
            production_promotion["env"]["PLAY_SERVICE_ACCOUNT_JSON"],
            "${{ secrets.PLAY_PRODUCTION_SERVICE_ACCOUNT_JSON }}",
        )
        self.assertNotIn("PLAY_TEST_SERVICE_ACCOUNT_JSON", str(production_promotion))
        self.assertNotIn("||", str(production_promotion["env"]))

    def test_manual_promotion_checks_out_script_before_invocation(self):
        steps = workflow()["jobs"]["promote_production"]["steps"]
        checkout_index = next(
            index for index, step in enumerate(steps)
            if step.get("uses", "").startswith("actions/checkout@")
        )
        script_index = next(
            index for index, step in enumerate(steps)
            if "scripts/promote_play_release.py" in step.get("run", "")
        )
        self.assertLess(checkout_index, script_index)

    def test_play_version_is_newer_than_rejected_version_code(self):
        pubspec = (ROOT / "pubspec.yaml").read_text()
        self.assertIn("version: 1.0.3+7", pubspec)


if __name__ == "__main__":
    unittest.main()
