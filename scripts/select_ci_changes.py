"""Select the mobile CI test files for the current GitHub event."""
import json
import os
import subprocess


# shortcut: shared web branches are manually listed; automate discovery if the list drifts.
WEB_CODE_PATHS = {
    "lib/app.dart",
    "lib/core/utils/file_downloader.dart",
    "lib/core/utils/report_file_action.dart",
    "lib/features/authentication/presentation/blocs/authentication_bloc.dart",
    "lib/features/authentication/presentation/pages/role_selection_page.dart",
    "lib/features/authentication/presentation/widgets/login_button.dart",
    "lib/features/dashboard/presentation/pages/dashboard_page.dart",
    "lib/features/harga/presentation/pages/harga_page.dart",
    "lib/features/main/presentation/pages/main_page.dart",
    "lib/features/nasabah/presentation/pages/nasabah_page.dart",
    "lib/features/nasabah/presentation/widgets/nasabah_table.dart",
    "lib/features/pengumuman/presentation/pages/pengumuman_kelola_page.dart",
    "lib/features/profile/presentation/cubit/profile_cubit.dart",
    "lib/features/profile/presentation/pages/profile_page.dart",
    "lib/features/transaksi/presentation/pages/laporan/laporan_page.dart",
    "lib/features/transaksi/presentation/widgets/aktivitas_list_view.dart",
    "lib/main_development.dart",
    "lib/main_production.dart",
}
BROWSER_TEST_PATHS = {
    "test/browser/file_downloader_test.dart",
    "test/features/authentication/presentation/widgets/google_sign_in_web_button_chrome.dart",
    "test/features/dashboard/presentation/pages/dashboard_page_test.dart",
    "test/report_download_browser_test.dart",
}
BROWSER_ONLY_TESTS = {
    "test/browser/file_downloader_test.dart",
    "test/report_download_browser_test.dart",
}

# Shards the full VM suite is split into on staging/main pushes. Single source
# for both the test_shards matrix and the coverage merge-step invariant.
UNIT_TEST_SHARDS = 4


def changed_paths(base, head, cwd=None):
    result = subprocess.run(
        ["git", "diff", "--name-only", "-z", "--diff-filter=ACMR", base, head],
        cwd=cwd,
        check=True,
        capture_output=True,
        text=True,
    )
    return sorted(set(result.stdout.split("\0")[:-1]))


def select_vm_tests(paths):
    return sorted(
        path
        for path in set(paths)
        if path.startswith("test/")
        and path.endswith("_test.dart")
        and path not in BROWSER_ONLY_TESTS
        and not path.startswith("test/browser/")
        and not any(
            marker in path.rsplit("/", 1)[-1].lower()
            for marker in ("browser", "chrome")
        )
    )


def select_browser_tests(paths):
    return sorted(
        path
        for path in set(paths)
        if path.startswith("test/")
        and path.endswith("_test.dart")
        and path not in BROWSER_TEST_PATHS
        and any(marker in path.lower() for marker in ("browser", "chrome"))
    )


def is_web_diff(paths):
    for path in paths:
        if path.startswith("web/") or path in WEB_CODE_PATHS | BROWSER_TEST_PATHS:
            return True
        if path.startswith("lib/") and any(
            marker in path.lower() for marker in ("/web_", "_web", "/browser/", "_browser")
        ):
            return True
        if path.startswith("lib/core/router/"):
            return True
        if path.startswith("test/") and any(
            marker in path.lower() for marker in ("/browser/", "browser", "web_", "_web", "chrome")
        ):
            return True
    return False


def mirror_test_path(path):
    """lib/features/foo/bar.dart -> candidate test/ mirrors, direct first.

    PRs that change lib/ code without touching a test file would otherwise run
    no VM tests at all; the sibling-mirror convention covers most features."""
    if not path.startswith("lib/") or not path.endswith(".dart"):
        return []
    parts = path[len("lib/"):-len(".dart")].split("/")
    candidates = ["test/" + "/".join(parts) + "_test.dart"]
    # Some screens are tested at directory level, e.g. harga_page_test.dart
    # beside harga_page.dart — the filename ends with the element kind.
    if parts and parts[-1].endswith(("page", "widget", "view", "provider", "cubit", "bloc", "notifier")):
        candidates.append("test/" + "/".join(parts[:-1]) + "_test.dart")
    return candidates


def is_full_suite(event_name, ref, paths=()):
    if event_name == "push" and ref in {"refs/heads/staging", "refs/heads/main"}:
        return True
    return event_name in {"push", "pull_request"} and any(
        path.startswith("lib/") and path.endswith(".dart") for path in paths
    )


def is_coverage_gate(event_name, ref):
    return event_name == "push" and ref == "refs/heads/staging"


def _base_and_head():
    event_name = os.environ["GITHUB_EVENT_NAME"]
    ref = os.environ["GITHUB_REF"]
    head = os.environ["GITHUB_SHA"]
    if event_name == "pull_request":
        return os.environ["PR_BASE_SHA"], os.environ["PR_HEAD_SHA"], event_name, ref
    if event_name == "push":
        base = os.environ["PUSH_BEFORE_SHA"]
        if not base or set(base) == {"0"}:
            try:
                base = subprocess.run(
                    ["git", "merge-base", "origin/staging", head],
                    check=True,
                    capture_output=True,
                    text=True,
                ).stdout.strip()
            except subprocess.CalledProcessError as error:
                raise RuntimeError(
                    "Cannot find a merge base with origin/staging for the first branch push."
                ) from error
        return base, head, event_name, ref
    raise ValueError(f"Unsupported event for test selection: {event_name}")


def main():
    base, head, event_name, ref = _base_and_head()
    paths = changed_paths(base, head)
    vm_tests = select_vm_tests(paths)
    # Also run sibling-mirror tests for changed lib/ sources, verified to exist
    # at HEAD so a stale candidate never reaches the runner.
    mirrored = set()
    for path in paths:
        for candidate in mirror_test_path(path):
            if candidate not in vm_tests and os.path.isfile(candidate):
                mirrored.add(candidate)
    vm_tests = sorted(set(vm_tests) | mirrored)
    outputs = {
        "base_sha": base,
        "browser_test_files": json.dumps(select_browser_tests(paths), separators=(",", ":")),
        "coverage_gates": str(is_coverage_gate(event_name, ref)).lower(),
        "full_suite": str(is_full_suite(event_name, ref, paths)).lower(),
        "has_vm_tests": str(bool(vm_tests)).lower(),
        "test_files": json.dumps(vm_tests, separators=(",", ":")),
        "unit_test_shards": str(UNIT_TEST_SHARDS),
        "web_changed": str(is_web_diff(paths)).lower(),
    }
    output_path = os.environ.get("GITHUB_OUTPUT")
    if output_path:
        try:
            with open(output_path, "a", encoding="utf-8") as output:
                for name, value in outputs.items():
                    output.write(f"{name}={value}\n")
        except OSError as error:
            raise RuntimeError("Cannot write CI change-selection outputs.") from error
    else:
        print(json.dumps(outputs, sort_keys=True))


if __name__ == "__main__":
    main()
