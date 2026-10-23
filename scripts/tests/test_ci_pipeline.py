"""Guard the sharded Flutter CI and coverage handoff to SonarCloud."""
import pathlib
import unittest

import yaml

ROOT = pathlib.Path(__file__).resolve().parents[2]


def workflow(name):
    return yaml.load((ROOT / ".github/workflows" / name).read_text(), Loader=yaml.BaseLoader)


class CiPipelineTest(unittest.TestCase):
    def test_full_suite_is_sharded_and_coverage_gates_use_merged_lcov(self):
        ci = workflow("ci.yml")
        tests = ci["jobs"]["test_shards"]
        self.assertEqual(tests["strategy"]["matrix"]["shard"], ["0", "1", "2", "3"])
        run_tests = next(step["run"] for step in tests["steps"] if step.get("name") == "Run tests with coverage")
        self.assertIn("--total-shards=${{ strategy.job-total }}", run_tests)
        self.assertIn("--shard-index=${{ matrix.shard }}", run_tests)

        coverage = ci["jobs"]["coverage"]
        self.assertEqual(coverage["needs"], ["test_shards", "browser_tests"])
        steps = coverage["steps"]
        names = [step.get("name") for step in steps]
        merge_index = names.index("Merge test coverage shards")
        self.assertLess(merge_index, names.index("Coverage report (fail under 25%)"))
        self.assertLess(merge_index, names.index("PR diff coverage (fail under 25%)"))
        merge = steps[merge_index]["run"]
        self.assertIn("coverage/shards/*/lcov-*.info", merge)
        self.assertIn("--add-tracefile", merge)

        verify = ci["jobs"]["verify"]
        self.assertEqual(verify["needs"], ["quality", "test_shards", "browser_tests", "coverage"])

    def test_sonar_consumes_ci_coverage_without_rerunning_tests(self):
        ci = workflow("ci.yml")
        sonar = ci["jobs"]["sonar"]
        self.assertEqual(sonar["needs"], "coverage")
        download = next(step for step in sonar["steps"] if step.get("uses") == "actions/download-artifact@v4")
        self.assertEqual(download["with"]["name"], "sonar-coverage")
        self.assertEqual(download["with"]["path"], "coverage")

        sonar_commands = "\n".join(str(step) for step in sonar["steps"])
        self.assertNotIn("flutter test", sonar_commands)
        self.assertNotIn("dart run test", sonar_commands)
        self.assertIn("coverage/lcov.info", sonar_commands)
        self.assertIn("coverage/browser.lcov.info", sonar_commands)
        self.assertFalse((ROOT / ".github/workflows/sonar.yml").exists())


if __name__ == "__main__":
    unittest.main()
