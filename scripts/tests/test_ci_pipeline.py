"""Guard diff-selected mobile tests and staging coverage/Sonar handoff."""
import pathlib
import unittest

import yaml

from scripts import select_ci_changes

ROOT = pathlib.Path(__file__).resolve().parents[2]


def workflow(name):
    return yaml.load((ROOT / ".github/workflows" / name).read_text(), Loader=yaml.BaseLoader)


class CiPipelineTest(unittest.TestCase):
    def test_changed_file_selection_controls_vm_and_browser_tests(self):
        ci = workflow("ci.yml")
        changes = ci["jobs"]["changes"]
        self.assertEqual(changes["outputs"]["test_files"], "${{ steps.select.outputs.test_files }}")
        self.assertEqual(changes["outputs"]["coverage_gates"], "${{ steps.select.outputs.coverage_gates }}")
        select = next(step for step in changes["steps"] if step.get("id") == "select")
        self.assertIn("scripts/select_ci_changes.py", select["run"])
        self.assertIn("pull_request.base.sha", str(select["env"]))
        self.assertIn("event.before", str(select["env"]))

    def test_flutter_jobs_use_the_shared_setup_action(self):
        ci = workflow("ci.yml")
        for name in ("quality", "test_shards", "changed_tests", "browser_tests"):
            uses = [step.get("uses") for step in ci["jobs"][name]["steps"]]
            self.assertIn("./.github/actions/setup-flutter", uses, f"{name} must use the composite setup action")
            self.assertFalse(
                [use for use in uses if use and use.startswith("subosito/")],
                f"{name} should not inline the flutter action",
            )
        action = yaml.load(
            (ROOT / ".github/actions/setup-flutter/action.yml").read_text(), Loader=yaml.BaseLoader
        )
        steps = [step.get("uses") or step.get("name") for step in action["runs"]["steps"]]
        self.assertIn("subosito/flutter-action@v2", steps)

        selected = ci["jobs"]["changed_tests"]
        self.assertIn("needs.changes.outputs.has_vm_tests", selected["if"])
        self.assertIn("needs.changes.outputs.full_suite", selected["if"])
        selected_run = next(
            step["run"] for step in selected["steps"] if step.get("name") == "Run changed test files with coverage"
        )
        self.assertIn("flutter test --coverage", selected_run)
        self.assertIn("test_files", selected_run)

        browser = ci["jobs"]["browser_tests"]
        self.assertIn("needs.changes.outputs.web_changed", browser["if"])
        self.assertIn("needs.changes.outputs.full_suite", browser["if"])
        self.assertIn("github.event_name == 'pull_request'", browser["if"])
        self.assertIn("browser_test_files", str(browser["steps"]))

    def test_staging_runs_all_shards_and_owns_coverage_gates(self):
        ci = workflow("ci.yml")
        tests = ci["jobs"]["test_shards"]
        self.assertIn("needs.changes.outputs.full_suite", tests["if"])
        self.assertEqual(tests["strategy"]["matrix"]["shard"], ["0", "1", "2", "3"])
        # Keep the matrix and the selector's shard count in sync; the merge step
        # asserts the artifact count against the same output.
        self.assertEqual(
            len(tests["strategy"]["matrix"]["shard"]), select_ci_changes.UNIT_TEST_SHARDS
        )
        run_tests = next(
            step["run"] for step in tests["steps"] if step.get("name") == "Run tests with coverage"
        )
        self.assertIn("--total-shards=${{ strategy.job-total }}", run_tests)
        self.assertIn("--shard-index=${{ matrix.shard }}", run_tests)
        shard_upload = next(step for step in tests["steps"] if step.get("uses") == "actions/upload-artifact@v4")
        self.assertEqual(shard_upload["with"]["name"], "unit-coverage-${{ matrix.shard }}")
        self.assertEqual(shard_upload["with"]["path"], "coverage/lcov-${{ matrix.shard }}.info")

        coverage = ci["jobs"]["coverage"]
        self.assertEqual(coverage["name"], "Coverage gates")
        self.assertIn("always()", coverage["if"])
        self.assertEqual(
            coverage["needs"], ["changes", "test_shards", "changed_tests", "browser_tests"]
        )
        steps = coverage["steps"]
        names = [step.get("name") for step in steps]
        merge_index = names.index("Merge LCOV for Sonar and staging gates")
        global_index = names.index("Coverage report (fail under 25%)")
        diff_index = names.index("Staging diff coverage (fail under 25%)")
        self.assertLess(merge_index, global_index)
        self.assertLess(merge_index, diff_index)
        self.assertEqual(steps[global_index]["if"], "needs.changes.outputs.coverage_gates == 'true'")
        self.assertEqual(steps[diff_index]["if"], "needs.changes.outputs.coverage_gates == 'true'")
        self.assertEqual(
            steps[diff_index]["env"]["BASE_SHA"], "${{ needs.changes.outputs.base_sha }}"
        )
        self.assertIn('--compare-branch="$BASE_SHA"', steps[diff_index]["run"])
        self.assertIn("--fail-under=25", steps[diff_index]["run"])
        self.assertIn("--add-tracefile", steps[merge_index]["run"])
        self.assertIn('for tracefile in "${unit_tracefiles[@]}"', steps[merge_index]["run"])
        self.assertIn("EXPECTED_SHARDS", str(steps[merge_index]["env"]))
        self.assertIn('"$EXPECTED_SHARDS"', steps[merge_index]["run"])
        self.assertIn("p+0 >= 25", steps[global_index]["run"])

    def test_verify_accepts_only_intentionally_skipped_jobs(self):
        ci = workflow("ci.yml")
        verify = ci["jobs"]["verify"]
        self.assertIn("always()", verify["if"])
        self.assertEqual(
            verify["needs"],
            ["changes", "quality", "test_shards", "changed_tests", "browser_tests", "coverage"],
        )
        check = next(step["run"] for step in verify["steps"] if step.get("name") == "Require applicable checks to pass")
        self.assertIn("FULL_SUITE", check)
        self.assertIn("HAS_VM_TESTS", check)
        self.assertIn("WEB_CHANGED", check)
        self.assertIn("EVENT_NAME", check)

    def test_sonar_consumes_same_run_coverage_without_rerunning_tests(self):
        ci = workflow("ci.yml")
        sonar = ci["jobs"]["sonar"]
        self.assertEqual(sonar["needs"], ["changes", "coverage", "verify"])
        self.assertIn("always()", sonar["if"])
        self.assertIn("needs.verify.result == 'success'", sonar["if"])
        self.assertIn("github.event_name == 'pull_request'", sonar["if"])
        self.assertIn("github.ref == 'refs/heads/staging'", sonar["if"])
        self.assertIn("github.ref == 'refs/heads/main'", sonar["if"])
        download = next(step for step in sonar["steps"] if step.get("uses") == "actions/download-artifact@v4")
        self.assertEqual(download["with"]["name"], "sonar-coverage")
        self.assertEqual(download["if"], "needs.coverage.outputs.has_coverage == 'true'")

        commands = "\n".join(str(step) for step in sonar["steps"])
        self.assertNotIn("flutter test", commands)
        self.assertNotIn("dart run test", commands)
        self.assertIn("sonar.dart.lcov.reportPaths", commands)
        self.assertIn("needs.coverage.outputs.sonar_reports", commands)
        self.assertIn("steps.sonar_args.outputs.args", commands)
        coverage_merge = next(
            step["run"]
            for step in ci["jobs"]["coverage"]["steps"]
            if step.get("name") == "Merge LCOV for Sonar and staging gates"
        )
        self.assertIn("coverage/lcov.info", coverage_merge)
        self.assertIn("coverage/browser.lcov.info", coverage_merge)
        self.assertFalse((ROOT / ".github/workflows/sonar.yml").exists())


if __name__ == "__main__":
    unittest.main()
