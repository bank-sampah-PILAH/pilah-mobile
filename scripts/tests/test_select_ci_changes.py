"""Tests for selecting the changed tests and web checks in CI."""
import os
import pathlib
import subprocess
import tempfile
import unittest
from unittest.mock import patch

from scripts.select_ci_changes import (
    _base_and_head,
    changed_paths,
    is_coverage_gate,
    is_full_suite,
    is_web_diff,
    select_browser_tests,
    select_vm_tests,
)


class SelectCiChangesTest(unittest.TestCase):
    def test_first_feature_push_uses_merge_base_with_staging(self):
        with patch.dict(
            os.environ,
            {
                "GITHUB_EVENT_NAME": "push",
                "GITHUB_REF": "refs/heads/feature/new",
                "GITHUB_SHA": "head-sha",
                "PUSH_BEFORE_SHA": "0" * 40,
            },
            clear=True,
        ), patch("scripts.select_ci_changes.subprocess.run") as run:
            run.return_value.stdout = "base-sha\n"
            self.assertEqual(
                _base_and_head(),
                ("base-sha", "head-sha", "push", "refs/heads/feature/new"),
            )
        run.assert_called_once_with(
            ["git", "merge-base", "origin/staging", "head-sha"],
            check=True,
            capture_output=True,
            text=True,
        )

    def test_changed_paths_omits_deleted_files(self):
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            subprocess.run(["git", "init", "-q", str(root)], check=True)
            subprocess.run(["git", "-C", str(root), "config", "user.name", "CI Test"], check=True)
            subprocess.run(["git", "-C", str(root), "config", "user.email", "ci@example.com"], check=True)

            changed = root / "test" / "changed_test.dart"
            deleted = root / "test" / "deleted_test.dart"
            changed.parent.mkdir(parents=True)
            changed.write_text("void main() {}\n")
            deleted.write_text("void main() {}\n")
            subprocess.run(["git", "-C", str(root), "add", "."], check=True)
            subprocess.run(["git", "-C", str(root), "commit", "-qm", "base"], check=True)
            base = subprocess.run(
                ["git", "-C", str(root), "rev-parse", "HEAD"],
                check=True,
                capture_output=True,
                text=True,
            ).stdout.strip()

            changed.write_text("void main() => print('changed');\n")
            deleted.unlink()
            (root / "test" / "added_test.dart").write_text("void main() {}\n")
            subprocess.run(["git", "-C", str(root), "add", "-A"], check=True)
            subprocess.run(["git", "-C", str(root), "commit", "-qm", "change"], check=True)

            self.assertEqual(
                changed_paths(base, "HEAD", cwd=root),
                ["test/added_test.dart", "test/changed_test.dart"],
            )

    def test_selects_only_changed_vm_test_files(self):
        self.assertEqual(
            select_vm_tests(
                [
                    "test/features/example_test.dart",
                    "test/browser/file_downloader_test.dart",
                    "test/report_download_browser_test.dart",
                    "test/features/new_browser_test.dart",
                    "test/features/new_chrome_test.dart",
                    "test/support/fixture.dart",
                    "lib/feature.dart",
                ]
            ),
            ["test/features/example_test.dart"],
        )

    def test_changed_browser_tests_are_returned_unless_in_the_fixed_suite(self):
        self.assertEqual(
            select_browser_tests(
                [
                    "test/browser/new_browser_test.dart",
                    "test/features/main/web_shell_style_test.dart",
                    "test/features/new_chrome_test.dart",
                    "test/report_download_browser_test.dart",
                    "test/browser/browser_helper.dart",
                    "test/support/fixture.dart",
                ]
            ),
            [
                "test/browser/new_browser_test.dart",
                "test/features/new_chrome_test.dart",
            ],
        )

    def test_web_diffs_include_web_sources_and_browser_test_paths(self):
        self.assertTrue(is_web_diff(["web/index.html"]))
        self.assertTrue(
            is_web_diff(
                ["lib/features/dashboard/presentation/widgets/dashboard_web_kpi_section.dart"]
            )
        )
        self.assertTrue(
            is_web_diff(["lib/features/profile/presentation/pages/profile_page.dart"])
        )
        self.assertTrue(is_web_diff(["test/report_download_browser_test.dart"]))
        self.assertTrue(is_web_diff(["test/features/main/web_shell_style_test.dart"]))
        self.assertTrue(
            is_web_diff(
                ["test/features/authentication/presentation/widgets/google_sign_in_web_button_chrome.dart"]
            )
        )
        self.assertTrue(
            is_web_diff(
                ["test/features/dashboard/presentation/pages/dashboard_page_test.dart"]
            )
        )

    def test_non_web_diff_does_not_schedule_browser_suite(self):
        self.assertFalse(
            is_web_diff(
                [
                    "lib/core/utils/file_downloader_io.dart",
                    "test/design/constants/radius_test.dart",
                    "README.md",
                ]
            )
        )

    def test_only_staging_and_existing_main_pushes_run_the_full_suite(self):
        self.assertTrue(is_full_suite("push", "refs/heads/staging"))
        self.assertTrue(is_coverage_gate("push", "refs/heads/staging"))
        self.assertFalse(is_coverage_gate("push", "refs/heads/main"))
        self.assertTrue(is_full_suite("push", "refs/heads/main"))
        self.assertFalse(is_full_suite("push", "refs/heads/feature/mobile-ci-speed"))
        self.assertFalse(is_full_suite("pull_request", "refs/pull/164/merge"))


if __name__ == "__main__":
    unittest.main()
